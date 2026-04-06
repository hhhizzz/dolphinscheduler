#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART_DIR="${ROOT}/kubernetes/dolphinscheduler"

tmp_values="$(mktemp)"
tmp_output="$(mktemp)"
trap 'rm -f "${tmp_values}" "${tmp_output}"' EXIT

cat <<'EOF' > "${tmp_values}"
image:
  registry: apache
  tag: dev-SNAPSHOT
  apiTag: dev-SNAPSHOT-base
  masterTag: dev-SNAPSHOT-base
  workerTag: dev-SNAPSHOT-base

serverPlugins:
  enabled: true
EOF

helm template ds-plugin-bundle "${CHART_DIR}" -f "${tmp_values}" > "${tmp_output}"

assert_contains() {
  local expected="$1"

  if ! rg -Fq "${expected}" "${tmp_output}"; then
    echo "missing expected content: ${expected}" >&2
    exit 1
  fi
}

assert_count() {
  local expected_count="$1"
  local pattern="$2"
  local actual_count

  actual_count="$(rg -F -c "${pattern}" "${tmp_output}")"
  if [[ "${actual_count}" != "${expected_count}" ]]; then
    echo "expected ${expected_count} occurrences of '${pattern}', got ${actual_count}" >&2
    exit 1
  fi
}

assert_contains "image: apache/dolphinscheduler-api:dev-SNAPSHOT-base"
assert_contains "image: apache/dolphinscheduler-master:dev-SNAPSHOT-base"
assert_contains "image: apache/dolphinscheduler-worker:dev-SNAPSHOT-base"
assert_contains "image: apache/dolphinscheduler-alert-server:dev-SNAPSHOT"
assert_contains "image: apache/dolphinscheduler-server-plugins:dev-SNAPSHOT"
assert_contains "mountPath: /opt/dolphinscheduler/plugins"
assert_contains 'command: ["/bin/bash", "-lc", "cp -a /opt/dolphinscheduler/plugins/. /plugin-volume/"]'
assert_count 3 "name: server-plugins-init"
assert_count 3 "mountPath: /opt/dolphinscheduler/plugins"
assert_count 3 "mountPath: /plugin-volume"
