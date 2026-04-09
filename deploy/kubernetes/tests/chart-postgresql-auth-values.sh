#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART_DIR="${ROOT}/kubernetes/dolphinscheduler"

tmp_output="$(mktemp)"
trap 'rm -f "${tmp_output}"' EXIT

helm template ds-postgresql-auth "${CHART_DIR}" > "${tmp_output}"

assert_contains() {
  local expected="$1"

  if ! rg -Fq "${expected}" "${tmp_output}"; then
    echo "missing expected content: ${expected}" >&2
    exit 1
  fi
}

assert_contains 'name: POSTGRES_USER'
assert_contains 'value: "root"'
assert_contains 'name: POSTGRES_DB'
assert_contains 'value: "dolphinscheduler"'
