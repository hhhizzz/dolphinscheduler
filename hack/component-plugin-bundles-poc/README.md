# Component Plugin Bundles K8s PoC

This PoC validates a `dev`-branch Kubernetes deployment model where:

- `api`, `master`, and `worker` use `*-base` images with no bundled plugins
- `server-plugins` is a separate image carrying `datasource`, `storage`, and `task` plugins
- init containers copy plugin files into `/opt/dolphinscheduler/plugins` before startup

Prerequisites: Docker Desktop Kubernetes is running locally, `kubectl` targets that cluster, and the `desktop-worker` runtime can import both the PoC images and the rendered chart's dependency images.

## Commands

```bash
hack/component-plugin-bundles-poc/scripts/build-dist.sh
hack/component-plugin-bundles-poc/scripts/build-images.sh
hack/component-plugin-bundles-poc/scripts/deploy.sh
hack/component-plugin-bundles-poc/scripts/verify.sh
```

## Cleanup

```bash
kubectl delete namespace ds-plugin-bundle-poc --ignore-not-found
kubectl uncordon desktop-worker2 desktop-worker3 desktop-worker4 desktop-worker5 || true
```
