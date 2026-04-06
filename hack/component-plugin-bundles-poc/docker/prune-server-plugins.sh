#!/usr/bin/env bash
set -euo pipefail

PLUGINS_DIR="/opt/dolphinscheduler/plugins"

for plugin_dir in datasource-plugins storage-plugins task-plugins; do
  test -d "${PLUGINS_DIR}/${plugin_dir}"
  find "${PLUGINS_DIR}/${plugin_dir}" -mindepth 2 -name "*.jar" -exec mv {} "${PLUGINS_DIR}/${plugin_dir}/" \;
  find "${PLUGINS_DIR}/${plugin_dir}" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
done

rm -rf "${PLUGINS_DIR}/alert-plugins"
