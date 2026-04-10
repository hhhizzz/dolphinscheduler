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
set -xeo pipefail

DOCKER_HUB=$1
DOCKER_TAG=$2
DOCKER_PLATFORM=${3:-${DOCKER_PLATFORM:-linux/amd64,linux/arm64}}
DOCKER_REPO_BASE=dolphinscheduler

CURRENT_HOME=$(dirname "$(readlink -f "$0")")

build_image() {
    local dockerfile=$1
    local image_name=$2
    local use_no_cache=${3:-false}
    local cmd=(docker buildx build --push)

    if [[ "${use_no_cache}" == "true" ]]; then
        cmd+=(--no-cache)
    fi
    if [[ -n "${DOCKER_PLATFORM}" ]]; then
        cmd+=(--platform "${DOCKER_PLATFORM}")
    fi

    cmd+=(
        -t "${DOCKER_HUB}/${DOCKER_REPO_BASE}-${image_name}:${DOCKER_TAG}"
        -f "${CURRENT_HOME}/${dockerfile}"
        .
    )

    "${cmd[@]}"
}

build_image api-server.dockerfile api true
build_image server-plugins.dockerfile server-plugins
build_image master-server.dockerfile master
build_image worker-server.dockerfile worker
build_image alert-server.dockerfile alert-server
build_image standalone-server.dockerfile standalone-server
build_image tools.dockerfile tools
