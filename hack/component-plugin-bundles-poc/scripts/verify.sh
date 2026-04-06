#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

API_BASE_PLUGIN_COUNT="${TMP_DIR}/api_base_plugin_count"
API_STORAGE_PLUGINS="${TMP_DIR}/api_storage_plugins"
API_VERIFY_LOGS="${TMP_DIR}/api_verify_logs"
WORKER_VERIFY_LOGS="${TMP_DIR}/worker_verify_logs"
STORAGE_OPERATOR_FAILURE_PATTERN='(^|[^[:alnum:]])StorageOperator([^[:alnum:]]|$)'

docker run --rm --entrypoint /bin/bash apache/dolphinscheduler-api:dev-SNAPSHOT-base -lc 'find /opt/dolphinscheduler/plugins -type f | wc -l' | tee "${API_BASE_PLUGIN_COUNT}"
test "$(tr -d '[:space:]' < "${API_BASE_PLUGIN_COUNT}")" = "0"

kubectl wait --for=condition=complete job/ds-plugin-bundle-poc-db-init-job -n ds-plugin-bundle-poc --timeout=300s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=api -n ds-plugin-bundle-poc --timeout=300s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=master -n ds-plugin-bundle-poc --timeout=300s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=worker -n ds-plugin-bundle-poc --timeout=300s

kubectl exec -n ds-plugin-bundle-poc statefulset/ds-plugin-bundle-poc-master -- find /opt/dolphinscheduler/plugins/datasource-plugins -maxdepth 1 -name "*.jar" -print -quit | tee "${TMP_DIR}/master_plugins"
test -s "${TMP_DIR}/master_plugins"

kubectl exec -n ds-plugin-bundle-poc deploy/ds-plugin-bundle-poc-api -- find /opt/dolphinscheduler/plugins/storage-plugins -maxdepth 1 -name "*.jar" | tee "${API_STORAGE_PLUGINS}"
test -s "${API_STORAGE_PLUGINS}"

kubectl logs -n ds-plugin-bundle-poc deploy/ds-plugin-bundle-poc-api --tail=400 | tee "${API_VERIFY_LOGS}"
kubectl logs -n ds-plugin-bundle-poc statefulset/ds-plugin-bundle-poc-worker --tail=400 | tee "${WORKER_VERIFY_LOGS}"

egrep 'S3StorageOperator' "${API_VERIFY_LOGS}"
egrep 'Started ApiApplicationServer' "${API_VERIFY_LOGS}"
egrep 'bucketName: dolphinscheduler' "${WORKER_VERIFY_LOGS}"
egrep 'PhysicalTaskEngineDelegator started' "${WORKER_VERIFY_LOGS}"

! egrep "NoSuchBeanDefinitionException|UnsatisfiedDependencyException|${STORAGE_OPERATOR_FAILURE_PATTERN}" "${API_VERIFY_LOGS}"
! egrep "NoSuchBeanDefinitionException|UnsatisfiedDependencyException|${STORAGE_OPERATOR_FAILURE_PATTERN}" "${WORKER_VERIFY_LOGS}"
