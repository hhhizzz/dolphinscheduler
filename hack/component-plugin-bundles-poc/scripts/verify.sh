#!/usr/bin/env bash
set -euo pipefail

docker run --rm --entrypoint /bin/bash apache/dolphinscheduler-api:dev-SNAPSHOT-base -lc 'find /opt/dolphinscheduler/plugins -type f | wc -l' | tee /tmp/api_base_plugin_count
test "$(cat /tmp/api_base_plugin_count | tr -d '[:space:]')" = "0"

kubectl wait --for=condition=complete job/ds-plugin-bundle-poc-db-init-job -n ds-plugin-bundle-poc --timeout=300s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=api -n ds-plugin-bundle-poc --timeout=300s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=master -n ds-plugin-bundle-poc --timeout=300s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=worker -n ds-plugin-bundle-poc --timeout=300s

kubectl exec -n ds-plugin-bundle-poc deploy/ds-plugin-bundle-poc-api -- find /opt/dolphinscheduler/plugins/storage-plugins -maxdepth 1 -name "*.jar" | tee /tmp/api_storage_plugins
test -s /tmp/api_storage_plugins

kubectl logs -n ds-plugin-bundle-poc deploy/ds-plugin-bundle-poc-api --tail=400 | egrep 'S3StorageOperator|Started ApiApplicationServer'
kubectl logs -n ds-plugin-bundle-poc statefulset/ds-plugin-bundle-poc-worker --tail=400 | egrep 'bucketName: dolphinscheduler|PhysicalTaskEngineDelegator started'

! kubectl logs -n ds-plugin-bundle-poc deploy/ds-plugin-bundle-poc-api --tail=400 | egrep 'NoSuchBeanDefinitionException|UnsatisfiedDependencyException'
! kubectl logs -n ds-plugin-bundle-poc statefulset/ds-plugin-bundle-poc-worker --tail=400 | egrep 'NoSuchBeanDefinitionException|UnsatisfiedDependencyException'
