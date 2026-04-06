#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
POC_DIR="${ROOT}/hack/component-plugin-bundles-poc"
BUILD_DIR="${POC_DIR}/build"

mkdir -p "${BUILD_DIR}"

./mvnw -pl :dolphinscheduler-dist -am -Prelease -DskipTests -Ddocker.build.skip=true -Dspotless.skip=true package
cp dolphinscheduler-dist/target/apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz "${BUILD_DIR}/release-bin.tar.gz"

./mvnw -pl :dolphinscheduler-dist -am -Pstaging -DskipTests -Ddocker.build.skip=true -Dspotless.skip=true package
cp dolphinscheduler-dist/target/apache-dolphinscheduler-dev-SNAPSHOT-bin.tar.gz "${BUILD_DIR}/staging-bin.tar.gz"
