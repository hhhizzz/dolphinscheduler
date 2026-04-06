#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART_DIR="${ROOT}/kubernetes/dolphinscheduler"

tmp_values_external="$(mktemp)"
tmp_values_default="$(mktemp)"
tmp_output_external="$(mktemp)"
tmp_output_default="$(mktemp)"
tmp_job_external="$(mktemp)"
tmp_job_default="$(mktemp)"
trap 'rm -f "${tmp_values_external}" "${tmp_values_default}" "${tmp_output_external}" "${tmp_output_default}" "${tmp_job_external}" "${tmp_job_default}"' EXIT

cat <<'EOF' > "${tmp_values_external}"
image:
  registry: apache
  tag: dev-SNAPSHOT
  pullPolicy: Never
  apiTag: dev-SNAPSHOT-base
  masterTag: dev-SNAPSHOT-base
  workerTag: dev-SNAPSHOT-base

serverPlugins:
  enabled: true

postgresql:
  enabled: false

zookeeper:
  enabled: false

minio:
  enabled: false

registryJdbc:
  enabled: true
  hikariConfig:
    enabled: true
    driverClassName: org.postgresql.Driver
    jdbcurl: jdbc:postgresql://verify-postgresql.default.svc.cluster.local:5432/dolphinscheduler?characterEncoding=utf8
    username: root
    password: root

externalDatabase:
  enabled: true
  type: postgresql
  host: verify-postgresql.default.svc.cluster.local
  port: "5432"
  username: root
  password: root
  database: dolphinscheduler
  params: characterEncoding=utf8
  driverClassName: org.postgresql.Driver
EOF

touch "${tmp_values_default}"

helm template ds-plugin-bundle "${CHART_DIR}" -f "${tmp_values_external}" > "${tmp_output_external}"
helm template ds-plugin-bundle "${CHART_DIR}" -f "${tmp_values_default}" > "${tmp_output_default}"
awk '/^  name: ds-plugin-bundle-db-init-job$/{flag=1} flag{print} /^---$/{if(flag){exit}}' "${tmp_output_external}" > "${tmp_job_external}"
awk '/^  name: ds-plugin-bundle-db-init-job$/{flag=1} flag{print} /^---$/{if(flag){exit}}' "${tmp_output_default}" > "${tmp_job_default}"

assert_contains() {
  local file="$1"
  local expected="$2"

  if ! rg -Fq "${expected}" "${file}"; then
    echo "missing expected content in ${file}: ${expected}" >&2
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"

  if rg -Fq "${unexpected}" "${file}"; then
    echo "unexpected content in ${file}: ${unexpected}" >&2
    exit 1
  fi
}

assert_contains "${tmp_job_external}" '"helm.sh/hook": pre-install,pre-upgrade,pre-rollback'
assert_contains "${tmp_job_external}" '"helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded'
assert_contains "${tmp_job_external}" 'value: "root"'
assert_contains "${tmp_job_external}" 'value: jdbc:postgresql://verify-postgresql.default.svc.cluster.local:5432/dolphinscheduler?characterEncoding=utf8'
assert_contains "${tmp_job_external}" 'value: "jdbc"'
assert_not_contains "${tmp_job_external}" 'name: ds-plugin-bundle-externaldb'
assert_not_contains "${tmp_job_external}" 'name: ds-plugin-bundle-registry-db'
assert_not_contains "${tmp_job_external}" 'configMapRef:'

assert_contains "${tmp_job_default}" '"helm.sh/hook": post-install,post-upgrade,post-rollback'
assert_contains "${tmp_job_default}" 'name: ds-plugin-bundle-postgresql'
assert_contains "${tmp_job_default}" 'name: ds-plugin-bundle-common'
