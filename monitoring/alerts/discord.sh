#!/bin/bash
#================================================
# Panda Script v2.0 - Discord Notifications
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

send_discord_alert() {
    local severity="$1"
    local alert_type="$2"
    local message="$3"
    local hostname="$4"
    
    local webhook_url=$(get_config discord webhook_url)
    
    [[ -z "$webhook_url" ]] && return 1
    
    local color
    case "$severity" in
        critical) color=16711680 ;;  # Red
        warning) color=16776960 ;;   # Yellow
        *) color=3447003 ;;          # Blue
    esac
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local json=$(cat << EOF
{
  "embeds": [{
    "title": "🐼 Panda Script Alert",
    "description": "$message",
    "color": $color,
    "fields": [
      {"name": "Severity", "value": "${severity^^}", "inline": true},
      {"name": "Type", "value": "${alert_type^^}", "inline": true},
      {"name": "Server", "value": "$hostname", "inline": true}
    ],
    "timestamp": "$timestamp"
  }]
}
EOF
)

    curl -s -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "$json" &>/dev/null
}

test_discord() {
    local webhook_url=$(get_config discord webhook_url)
    
    [[ -z "$webhook_url" ]] && { log_error "Discord webhook not configured"; return 1; }
    
    send_discord_alert "info" "test" "Test message from Panda Script" "$(hostname)"
    log_success "Discord test message sent"
}
