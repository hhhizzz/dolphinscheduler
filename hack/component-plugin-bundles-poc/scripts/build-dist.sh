#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
POC_DIR="${ROOT}/hack/component-plugin-bundles-poc"
BUILD_DIR="${POC_DIR}/build"

mkdir -p "${BUILD_DIR}"

rm -rf "${ROOT}/dolphinscheduler-dist/target"

(
  cd "${ROOT}"
  ./mvnw -pl :dolphinscheduler-dist -am -Prelease -DskipTests -Ddocker.build.skip=true -Dspotless.skip=true package
)
cp "${ROOT}/dolphinscheduler-dist/target/apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz" "${BUILD_DIR}/release-bin.tar.gz"

rm -rf "${ROOT}/dolphinscheduler-dist/target"

(
  cd "${ROOT}"
  ./mvnw -pl :dolphinscheduler-dist -am -Pstaging -DskipTests -Ddocker.build.skip=true -Dspotless.skip=true package
)
cp "${ROOT}/dolphinscheduler-dist/target/apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz" "${BUILD_DIR}/staging-bin.tar.gz"
