#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
POC_DIR="${ROOT}/hack/component-plugin-bundles-poc"
RENDER_DIR="${POC_DIR}/k8s/rendered"

mkdir -p "${RENDER_DIR}"

helm template ds-plugin-bundle-poc "${ROOT}/deploy/kubernetes/dolphinscheduler" \
  --namespace ds-plugin-bundle-poc \
  -f "${POC_DIR}/k8s/values-poc.yaml" \
  > "${RENDER_DIR}/base.yaml"
