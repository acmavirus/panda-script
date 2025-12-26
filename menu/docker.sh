#!/bin/bash
#================================================
# Panda Script v2.0 - Docker Menu
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

docker_menu() {
    source "$PANDA_DIR/modules/docker/install.sh"
    manage_containers
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    docker_menu
fi
