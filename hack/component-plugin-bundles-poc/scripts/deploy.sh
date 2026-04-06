#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
POC_DIR="${ROOT}/hack/component-plugin-bundles-poc"

kubectl cordon desktop-worker2 desktop-worker3 desktop-worker4 desktop-worker5 || true
kubectl delete namespace ds-plugin-bundle-poc --ignore-not-found --wait=false || true
kubectl wait --for=delete namespace/ds-plugin-bundle-poc --timeout=180s >/dev/null 2>&1 || true

"${POC_DIR}/scripts/render-base.sh"
"${POC_DIR}/scripts/load-images.sh"

kubectl apply -k "${POC_DIR}/k8s"
