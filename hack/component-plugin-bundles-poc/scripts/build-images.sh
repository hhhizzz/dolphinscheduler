#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
POC_DIR="${ROOT}/hack/component-plugin-bundles-poc"
BUILD_DIR="${POC_DIR}/build"
DOCKER_DIR="${POC_DIR}/docker"

test -f "${BUILD_DIR}/release-bin.tar.gz"
test -f "${BUILD_DIR}/staging-bin.tar.gz"

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
