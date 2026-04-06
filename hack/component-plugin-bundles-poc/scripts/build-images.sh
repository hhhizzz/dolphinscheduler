#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
POC_DIR="${ROOT}/hack/component-plugin-bundles-poc"
BUILD_DIR="${POC_DIR}/build"
DOCKER_DIR="${POC_DIR}/docker"
TOOLS_IMAGE="apache/dolphinscheduler-tools:dev-SNAPSHOT"

assert_empty_plugins_dir() {
  local image="$1"
  local actual

  actual="$(
    docker run --rm "${image}" bash -lc \
      'find /opt/dolphinscheduler/plugins -mindepth 1 -maxdepth 1 -print -quit'
  )"
  test -z "${actual}"
}

assert_server_plugins_image() {
  local image="$1"
  local actual
  local expected=$'datasource-plugins\nstorage-plugins\ntask-plugins'

  actual="$(
    docker run --rm "${image}" bash -lc \
      'find /opt/dolphinscheduler/plugins -mindepth 1 -maxdepth 1 -printf "%f\n" | sort'
  )"
  test "${actual}" = "${expected}"

  docker run --rm "${image}" bash -lc \
    'test -z "$(find /opt/dolphinscheduler/plugins -name '\''._*'\'' -print -quit)"'
  docker run --rm "${image}" bash -lc \
    'test ! -e /opt/dolphinscheduler/plugins/alert-plugins'
}

test -f "${BUILD_DIR}/release-bin.tar.gz"
test -f "${BUILD_DIR}/staging-bin.tar.gz"

tmp_plugins_dir="$(mktemp -d)"
tmp_tools_context="$(mktemp -d)"
trap 'rm -rf "${tmp_plugins_dir}" "${tmp_tools_context}"' EXIT
mkdir -p \
  "${tmp_plugins_dir}/datasource-plugins/alpha/beta" \
  "${tmp_plugins_dir}/storage-plugins/gamma/delta" \
  "${tmp_plugins_dir}/task-plugins/epsilon/zeta" \
  "${tmp_plugins_dir}/alert-plugins/theta/iota"
mkdir -p "${tmp_tools_context}/target"
touch \
  "${tmp_plugins_dir}/._alert-plugins" \
  "${tmp_plugins_dir}/._datasource-plugins" \
  "${tmp_plugins_dir}/._storage-plugins" \
  "${tmp_plugins_dir}/._task-plugins" \
  "${tmp_plugins_dir}/datasource-plugins/alpha/beta/plugin-a.jar" \
  "${tmp_plugins_dir}/datasource-plugins/alpha/beta/._plugin-a.jar" \
  "${tmp_plugins_dir}/storage-plugins/gamma/delta/plugin-b.jar" \
  "${tmp_plugins_dir}/storage-plugins/gamma/delta/._plugin-b.jar" \
  "${tmp_plugins_dir}/task-plugins/epsilon/zeta/plugin-c.jar" \
  "${tmp_plugins_dir}/task-plugins/epsilon/zeta/._plugin-c.jar" \
  "${tmp_plugins_dir}/alert-plugins/theta/iota/plugin-d.jar" \
  "${tmp_plugins_dir}/alert-plugins/theta/iota/._plugin-d.jar"
PLUGINS_DIR="${tmp_plugins_dir}" bash "${DOCKER_DIR}/prune-server-plugins.sh"
test -f "${tmp_plugins_dir}/datasource-plugins/plugin-a.jar"
test -f "${tmp_plugins_dir}/storage-plugins/plugin-b.jar"
test -f "${tmp_plugins_dir}/task-plugins/plugin-c.jar"
test ! -e "${tmp_plugins_dir}/alert-plugins"
test ! -e "${tmp_plugins_dir}/._alert-plugins"
test ! -e "${tmp_plugins_dir}/._datasource-plugins"
test ! -e "${tmp_plugins_dir}/._storage-plugins"
test ! -e "${tmp_plugins_dir}/._task-plugins"
test -z "$(find "${tmp_plugins_dir}" -name '._*' -print -quit)"
test -z "$(find "${tmp_plugins_dir}/datasource-plugins" -mindepth 2 -type d -print -quit)"
test -z "$(find "${tmp_plugins_dir}/storage-plugins" -mindepth 2 -type d -print -quit)"
test -z "$(find "${tmp_plugins_dir}/task-plugins" -mindepth 2 -type d -print -quit)"
cp "${BUILD_DIR}/release-bin.tar.gz" \
  "${tmp_tools_context}/target/apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz"

docker buildx build --load \
  -t apache/dolphinscheduler-api:dev-SNAPSHOT-base \
  -f "${DOCKER_DIR}/api-base.dockerfile" "${POC_DIR}"

docker buildx build --load \
  -t apache/dolphinscheduler-master:dev-SNAPSHOT-base \
  -f "${DOCKER_DIR}/master-base.dockerfile" "${POC_DIR}"

docker buildx build --load \
  -t apache/dolphinscheduler-worker:dev-SNAPSHOT-base \
  -f "${DOCKER_DIR}/worker-base.dockerfile" "${POC_DIR}"

docker buildx build --load \
  -t apache/dolphinscheduler-server-plugins:dev-SNAPSHOT \
  -f "${DOCKER_DIR}/server-plugins.dockerfile" "${POC_DIR}"

docker buildx build --load \
  -t "${TOOLS_IMAGE}" \
  -f "${ROOT}/dolphinscheduler-dist/src/main/docker/tools.dockerfile" \
  "${tmp_tools_context}"

assert_empty_plugins_dir "apache/dolphinscheduler-api:dev-SNAPSHOT-base"
assert_empty_plugins_dir "apache/dolphinscheduler-master:dev-SNAPSHOT-base"
assert_empty_plugins_dir "apache/dolphinscheduler-worker:dev-SNAPSHOT-base"
assert_server_plugins_image "apache/dolphinscheduler-server-plugins:dev-SNAPSHOT"
