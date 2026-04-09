#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART_DIR="${ROOT}/kubernetes/dolphinscheduler"

tmp_output="$(mktemp)"
trap 'rm -f "${tmp_output}"' EXIT

helm template ds-datasource "${CHART_DIR}" > "${tmp_output}"

if ! rg -Fq 'postgresql-password:' "${tmp_output}"; then
  echo "missing generated postgresql-password secret key in rendered chart" >&2
  exit 1
fi

mapfile -t datasource_keys < <(
  awk '
    $1 == "-" && $2 == "name:" && $3 == "SPRING_DATASOURCE_PASSWORD" { capture = 1; next }
    capture && $1 == "key:" { print $2; capture = 0 }
  ' "${tmp_output}"
)

if [[ "${#datasource_keys[@]}" -eq 0 ]]; then
  echo "did not find any SPRING_DATASOURCE_PASSWORD secret key references" >&2
  exit 1
fi

for key in "${datasource_keys[@]}"; do
  if [[ "${key}" != "postgresql-password" ]]; then
    echo "expected SPRING_DATASOURCE_PASSWORD to use postgresql-password, got ${key}" >&2
    exit 1
  fi
done
