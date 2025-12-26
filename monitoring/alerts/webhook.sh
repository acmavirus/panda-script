#!/bin/bash
#================================================
# Panda Script v2.0 - Webhook Notifications
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

send_webhook_alert() {
    local severity="$1"
    local alert_type="$2"
    local message="$3"
    local hostname="$4"
    
    local webhook_url=$(get_config webhook url)
    local auth_token=$(get_config webhook auth_token)
    
    [[ -z "$webhook_url" ]] && return 1
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local json=$(cat << EOF
{
  "event": "panda_alert",
  "severity": "$severity",
  "type": "$alert_type",
  "message": "$message",
  "hostname": "$hostname",
  "timestamp": "$timestamp"
}
EOF
)

    local headers="-H 'Content-Type: application/json'"
    [[ -n "$auth_token" ]] && headers="$headers -H 'Authorization: Bearer $auth_token'"
    
    curl -s -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        ${auth_token:+-H "Authorization: Bearer $auth_token"} \
        -d "$json" &>/dev/null
}

test_webhook() {
    local webhook_url=$(get_config webhook url)
    [[ -z "$webhook_url" ]] && { log_error "Webhook not configured"; return 1; }
    
    send_webhook_alert "info" "test" "Test webhook from Panda Script" "$(hostname)"
    log_success "Webhook test sent"
}
