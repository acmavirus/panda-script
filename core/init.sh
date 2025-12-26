#!/bin/bash
#================================================
# Panda Script v2.0 - Core Initialization
# Bootstrap & environment initialization
# Website: https://panda-script.com
#================================================

# Panda installation directory
export PANDA_DIR="${PANDA_DIR:-/opt/panda}"
export PANDA_VERSION="2.0.0"

# Directory paths
export PANDA_CORE_DIR="$PANDA_DIR/core"
export PANDA_CONFIG_DIR="$PANDA_DIR/config"
export PANDA_DATA_DIR="$PANDA_DIR/data"
export PANDA_LOG_DIR="$PANDA_DIR/data/logs"
export PANDA_TMP_DIR="$PANDA_DIR/data/tmp"
export PANDA_DB_FILE="$PANDA_DIR/data/db/panda.db"

# Config files
export PANDA_CONF="$PANDA_CONFIG_DIR/panda.conf"
export ALERTS_CONF="$PANDA_CONFIG_DIR/alerts.conf"
export THRESHOLDS_CONF="$PANDA_CONFIG_DIR/thresholds.conf"
export SECURITY_CONF="$PANDA_CONFIG_DIR/security.conf"

#------------------------------------------------
# Load Configuration
#------------------------------------------------
load_config() {
    local config_file="$1"
    local section=""
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Detect section
        if [[ "$line" =~ ^\[([a-zA-Z0-9_]+)\] ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Parse key=value
        if [[ "$line" =~ ^([a-zA-Z0-9_]+)[[:space:]]*=[[:space:]]*(.*) ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            # Remove quotes
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            
            # Create variable with section prefix
            if [[ -n "$section" ]]; then
                declare -g "CONFIG_${section^^}_${key^^}=$value"
            fi
        fi
    done < "$config_file"
}

#------------------------------------------------
# Get Config Value
#------------------------------------------------
get_config() {
    local section="$1"
    local key="$2"
    local default="$3"
    
    local var_name="CONFIG_${section^^}_${key^^}"
    local value="${!var_name}"
    
    echo "${value:-$default}"
}

#------------------------------------------------
# Initialize Environment
#------------------------------------------------
init_environment() {
    # Create necessary directories
    mkdir -p "$PANDA_LOG_DIR" "$PANDA_TMP_DIR"
    
    # Load all config files
    [[ -f "$PANDA_CONF" ]] && load_config "$PANDA_CONF"
    [[ -f "$ALERTS_CONF" ]] && load_config "$ALERTS_CONF"
    [[ -f "$THRESHOLDS_CONF" ]] && load_config "$THRESHOLDS_CONF"
    [[ -f "$SECURITY_CONF" ]] && load_config "$SECURITY_CONF"
}

#------------------------------------------------
# Load Core Modules
#------------------------------------------------
load_core_modules() {
    local modules=(
        "common.sh"
        "os_detect.sh"
        "package.sh"
        "service.sh"
        "network.sh"
        "utils.sh"
    )
    
    for module in "${modules[@]}"; do
        if [[ -f "$PANDA_CORE_DIR/$module" ]]; then
            source "$PANDA_CORE_DIR/$module"
        fi
    done
}

#------------------------------------------------
# Check Root
#------------------------------------------------
require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This command requires root privileges."
        echo "Please run with sudo or as root."
        exit 1
    fi
}

#------------------------------------------------
# Initialize
#------------------------------------------------
panda_init() {
    init_environment
    load_core_modules
}

# Auto-initialize when sourced
panda_init
