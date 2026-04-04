#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -euo pipefail

DOLPHINSCHEDULER_HOME=${DOLPHINSCHEDULER_HOME:-/opt/dolphinscheduler}
PLUGINS_DIR="${DOLPHINSCHEDULER_HOME}/plugins"

if [ ! -d "${PLUGINS_DIR}" ]; then
  exit 0
fi

if [ $# -eq 0 ]; then
  exit 0
fi

for plugin_dir in "${PLUGINS_DIR}"/*; do
  if [ ! -d "${plugin_dir}" ]; then
    continue
  fi

  find "${plugin_dir}" -mindepth 2 -name "*.jar" -exec mv {} "${plugin_dir}/" \;
  find "${plugin_dir}" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;
done

for plugin_dir in "${PLUGINS_DIR}"/*; do
  if [ ! -d "${plugin_dir}" ]; then
    continue
  fi

  keep_plugin_dir=false
  for keep_dir in "$@"; do
    if [ "$(basename "${plugin_dir}")" = "${keep_dir}" ]; then
      keep_plugin_dir=true
      break
    fi
  done

  if [ "${keep_plugin_dir}" = false ]; then
    rm -rf "${plugin_dir}"
  fi
done
