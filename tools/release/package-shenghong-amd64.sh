#!/usr/bin/env bash
set -euo pipefail

CURRENT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${CURRENT_HOME}/../.." && pwd)"
CHART_DIR="${REPO_ROOT}/deploy/kubernetes/dolphinscheduler"
DIST_DIR="${REPO_ROOT}/dolphinscheduler-dist"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/dist/shenghong-amd64}"
VERSION_SUFFIX="${VERSION_SUFFIX:-shenghong}"
IMAGE_REGISTRY="${IMAGE_REGISTRY:-apache}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"
MAVEN_USER_HOME="${MAVEN_USER_HOME:-${TMPDIR:-/tmp}/dolphinscheduler-maven-home}"
MAVEN_REPO_LOCAL="${MAVEN_REPO_LOCAL:-${TMPDIR:-/tmp}/dolphinscheduler-maven-repo}"
HELM_HOME_BASE="${HELM_HOME_BASE:-${TMPDIR:-/tmp}/dolphinscheduler-helm}"
BUILD_JAVA_HOME="${BUILD_JAVA_HOME:-}"
SKIP_MAVEN_PACKAGE="${SKIP_MAVEN_PACKAGE:-false}"

export HELM_CACHE_HOME="${HELM_CACHE_HOME:-${HELM_HOME_BASE}/cache}"
export HELM_CONFIG_HOME="${HELM_CONFIG_HOME:-${HELM_HOME_BASE}/config}"
export HELM_DATA_HOME="${HELM_DATA_HOME:-${HELM_HOME_BASE}/data}"

if [[ -z "${BUILD_JAVA_HOME}" ]] && [[ -x /usr/libexec/java_home ]]; then
    BUILD_JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
fi

if [[ -n "${BUILD_JAVA_HOME}" ]]; then
    export JAVA_HOME="${BUILD_JAVA_HOME}"
    export PATH="${JAVA_HOME}/bin:${PATH}"
fi

PROJECT_VERSION="$(
    sed -n '/<artifactId>dolphinscheduler<\/artifactId>/,/<packaging>/s@.*<version>\(.*\)</version>.*@\1@p' \
        "${REPO_ROOT}/pom.xml" | head -n 1
)"
CHART_VERSION_BASE="$(sed -n 's/^version: //p' "${CHART_DIR}/Chart.yaml" | head -n 1)"
IMAGE_TAG="${PROJECT_VERSION}-${VERSION_SUFFIX}"
CHART_VERSION="${CHART_VERSION_BASE}-${VERSION_SUFFIX}"
IMAGE_ARCHIVE="${OUTPUT_DIR}/dolphinscheduler-images-${IMAGE_TAG}-linux-amd64.tar.gz"
RENDERED_MANIFEST="${OUTPUT_DIR}/dolphinscheduler-${IMAGE_TAG}.rendered.yaml"
VALUES_OUTPUT="${OUTPUT_DIR}/values-${VERSION_SUFFIX}.yaml"
TEMP_HELM_WORKDIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_HELM_WORKDIR}"' EXIT
TEMP_CHART_DIR="${TEMP_HELM_WORKDIR}/dolphinscheduler"

mkdir -p \
    "${OUTPUT_DIR}" \
    "${MAVEN_USER_HOME}" \
    "${MAVEN_REPO_LOCAL}" \
    "${HELM_CACHE_HOME}" \
    "${HELM_CONFIG_HOME}" \
    "${HELM_DATA_HOME}"

cp -R "${CHART_DIR}" "${TEMP_CHART_DIR}"

cat > "${VALUES_OUTPUT}" <<EOF
image:
  registry: ${IMAGE_REGISTRY}
  tag: ${IMAGE_TAG}
  pullPolicy: IfNotPresent
serverPlugins:
  enabled: true
EOF

if [[ "${SKIP_MAVEN_PACKAGE}" != "true" ]]; then
    (
        cd "${REPO_ROOT}"
        env MAVEN_USER_HOME="${MAVEN_USER_HOME}" ./mvnw \
            -Dmaven.repo.local="${MAVEN_REPO_LOCAL}" \
            -Prelease \
            -Dbuild.plugins.skip=false \
            -pl dolphinscheduler-dist \
            -am \
            -Dspotless.skip=true \
            -DskipTests \
            package
    )
fi

(
    cd "${DIST_DIR}"
    DOCKER_PLATFORM="${DOCKER_PLATFORM}" bash src/main/docker/docker-build.sh "${IMAGE_REGISTRY}" "${IMAGE_TAG}"
)

docker save \
    "${IMAGE_REGISTRY}/dolphinscheduler-api:${IMAGE_TAG}" \
    "${IMAGE_REGISTRY}/dolphinscheduler-server-plugins:${IMAGE_TAG}" \
    "${IMAGE_REGISTRY}/dolphinscheduler-master:${IMAGE_TAG}" \
    "${IMAGE_REGISTRY}/dolphinscheduler-worker:${IMAGE_TAG}" \
    "${IMAGE_REGISTRY}/dolphinscheduler-alert-server:${IMAGE_TAG}" \
    "${IMAGE_REGISTRY}/dolphinscheduler-tools:${IMAGE_TAG}" \
    -o "${IMAGE_ARCHIVE%.gz}"
gzip -f "${IMAGE_ARCHIVE%.gz}"

helm dependency update "${TEMP_CHART_DIR}"
helm lint "${TEMP_CHART_DIR}" -f "${VALUES_OUTPUT}"
helm template ds-shenghong "${TEMP_CHART_DIR}" -f "${VALUES_OUTPUT}" > "${RENDERED_MANIFEST}"
helm package "${TEMP_CHART_DIR}" \
    --app-version "${IMAGE_TAG}" \
    --version "${CHART_VERSION}" \
    --destination "${OUTPUT_DIR}"

echo "image_tag=${IMAGE_TAG}"
echo "chart_version=${CHART_VERSION}"
echo "output_dir=${OUTPUT_DIR}"
echo "image_archive=${IMAGE_ARCHIVE}"
echo "rendered_manifest=${RENDERED_MANIFEST}"
