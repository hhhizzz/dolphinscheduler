#!/usr/bin/env bash
set -euo pipefail

for node in desktop-worker; do
  docker save \
    apache/dolphinscheduler-api:dev-SNAPSHOT-base \
    apache/dolphinscheduler-master:dev-SNAPSHOT-base \
    apache/dolphinscheduler-worker:dev-SNAPSHOT-base \
    apache/dolphinscheduler-server-plugins:dev-SNAPSHOT \
  | docker exec -i "${node}" ctr -n k8s.io images import -
done
