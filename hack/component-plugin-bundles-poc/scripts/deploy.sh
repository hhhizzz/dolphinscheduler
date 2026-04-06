#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
POC_DIR="${ROOT}/hack/component-plugin-bundles-poc"
NAMESPACE="ds-plugin-bundle-poc"
WORKER_NODES=(desktop-worker2 desktop-worker3 desktop-worker4 desktop-worker5)

fail() {
  echo "deploy: $*" >&2
  exit 1
}

if ! kubectl cordon "${WORKER_NODES[@]}"; then
  fail "failed to cordon worker nodes: ${WORKER_NODES[*]}"
fi

if kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  if ! kubectl delete namespace "${NAMESPACE}" --wait=false; then
    fail "failed to delete namespace ${NAMESPACE}"
  fi

  if ! kubectl wait --for=delete "namespace/${NAMESPACE}" --timeout=180s >/dev/null 2>&1; then
    fail "timed out waiting for namespace ${NAMESPACE} to be deleted"
  fi

  if kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
    fail "namespace ${NAMESPACE} still exists after teardown"
  fi
fi

"${POC_DIR}/scripts/render-base.sh"
"${POC_DIR}/scripts/load-images.sh"

if ! kubectl create namespace "${NAMESPACE}"; then
  fail "failed to create namespace ${NAMESPACE}"
fi

if ! kubectl apply -k "${POC_DIR}/k8s"; then
  fail "failed to apply kustomize overlay"
fi
