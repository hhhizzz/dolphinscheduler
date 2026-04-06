#!/usr/bin/env bash
set -euo pipefail

ensure_image() {
  local image="$1"

  docker image inspect "${image}" >/dev/null 2>&1 || docker pull "${image}"
}

ensure_image "docker.io/bitnamilegacy/postgresql:11.11.0"
ensure_image "docker.io/bitnamilegacy/zookeeper:3.8.4"
ensure_image "docker.io/bitnamilegacy/minio:2022.10.29-debian-11-r0"
ensure_image "docker.io/library/busybox:1.30.1"

for node in desktop-worker; do
  docker save \
    apache/dolphinscheduler-api:dev-SNAPSHOT-base \
    apache/dolphinscheduler-master:dev-SNAPSHOT-base \
    apache/dolphinscheduler-worker:dev-SNAPSHOT-base \
    apache/dolphinscheduler-server-plugins:dev-SNAPSHOT \
    apache/dolphinscheduler-tools:dev-SNAPSHOT \
    docker.io/bitnamilegacy/postgresql:11.11.0 \
    docker.io/bitnamilegacy/zookeeper:3.8.4 \
    docker.io/bitnamilegacy/minio:2022.10.29-debian-11-r0 \
    docker.io/library/busybox:1.30.1 \
  | docker exec -i "${node}" ctr -n k8s.io images import -
done
