#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART_DIR="${ROOT}/kubernetes/dolphinscheduler"
HELM_HOME_BASE="${HELM_HOME_BASE:-${TMPDIR:-/tmp}/dolphinscheduler-helm}"

export HELM_CACHE_HOME="${HELM_CACHE_HOME:-${HELM_HOME_BASE}/cache}"
export HELM_CONFIG_HOME="${HELM_CONFIG_HOME:-${HELM_HOME_BASE}/config}"
export HELM_DATA_HOME="${HELM_DATA_HOME:-${HELM_HOME_BASE}/data}"

mkdir -p "${HELM_CACHE_HOME}" "${HELM_CONFIG_HOME}" "${HELM_DATA_HOME}"

tmp_chart_root="$(mktemp -d)"
tmp_output="$(mktemp)"
trap 'rm -rf "${tmp_chart_root}" "${tmp_output}"' EXIT

cp -R "${CHART_DIR}" "${tmp_chart_root}/dolphinscheduler"
TEMP_CHART_DIR="${tmp_chart_root}/dolphinscheduler"
VALUES_FILE="${TEMP_CHART_DIR}/values-shenghong.yaml"

helm dependency update "${TEMP_CHART_DIR}" >/dev/null
helm template ds-shenghong "${TEMP_CHART_DIR}" -f "${VALUES_FILE}" > "${tmp_output}"

assert_contains() {
  local expected="$1"

  if ! rg -Fq "${expected}" "${tmp_output}"; then
    echo "missing expected content: ${expected}" >&2
    exit 1
  fi
}

assert_contains "image: apache/dolphinscheduler-api:dev-SNAPSHOT-shenghong"
assert_contains "image: apache/dolphinscheduler-master:dev-SNAPSHOT-shenghong"
assert_contains "image: apache/dolphinscheduler-worker:dev-SNAPSHOT-shenghong"
assert_contains "image: apache/dolphinscheduler-alert-server:dev-SNAPSHOT-shenghong"
assert_contains "image: apache/dolphinscheduler-tools:dev-SNAPSHOT-shenghong"
assert_contains "image: apache/dolphinscheduler-server-plugins:dev-SNAPSHOT-shenghong"
assert_contains "name: server-plugins-init"
assert_contains "mountPath: /opt/dolphinscheduler/plugins"
