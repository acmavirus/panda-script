#!/bin/bash
#================================================
# Panda Script v2.0 - Alert Manager
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

ALERT_LOG="${PANDA_LOG_DIR:-/opt/panda/data/logs}/alerts.log"
LAST_ALERT_FILE="${PANDA_TMP_DIR:-/opt/panda/data/tmp}/last_alert"

send_alert() {
    local alert_type="$1"   # ddos, ram, cpu, disk, service, security
    local severity="$2"     # info, warning, critical
    local message="$3"
    local details="$4"
    
    # Rate limiting check
    if ! should_send_alert "$alert_type"; then
        log_debug "Alert rate limited: $alert_type"
        return 0
    fi
    
    # Log alert
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$severity] [$alert_type] $message" >> "$ALERT_LOG"
    
    # Save to database
    db_query "INSERT INTO alerts (type, severity, message, details) VALUES ('$alert_type', '$severity', '$message', '$details')"
    
    # Send to enabled channels
    local hostname=$(hostname)
    
    # Telegram
    if [[ "$(get_config telegram enabled)" == "true" ]]; then
        source "${PANDA_DIR}/monitoring/alerts/telegram.sh"
        send_telegram_alert "$severity" "$alert_type" "$message" "$hostname"
    fi
    
    # Email
    if [[ "$(get_config email enabled)" == "true" ]]; then
        source "${PANDA_DIR}/monitoring/alerts/email.sh"
        send_email_alert "$severity" "$alert_type" "$message" "$hostname"
    fi
    
    # Discord
    if [[ "$(get_config discord enabled)" == "true" ]]; then
        source "${PANDA_DIR}/monitoring/alerts/discord.sh"
        send_discord_alert "$severity" "$alert_type" "$message" "$hostname"
    fi
    
    # Webhook
    if [[ "$(get_config webhook enabled)" == "true" ]]; then
        source "${PANDA_DIR}/monitoring/alerts/webhook.sh"
        send_webhook_alert "$severity" "$alert_type" "$message" "$hostname"
    fi
    
    # Update last alert time
    echo "$(date +%s) $alert_type" >> "$LAST_ALERT_FILE"
    
    log_info "Alert sent: [$severity] $alert_type - $message"
}

should_send_alert() {
    local alert_type="$1"
    local rate_limit=$(get_config telegram rate_limit_seconds 60)
    local now=$(date +%s)
    
    [[ ! -f "$LAST_ALERT_FILE" ]] && return 0
    
    local last_time=$(grep "$alert_type" "$LAST_ALERT_FILE" | tail -1 | awk '{print $1}')
    [[ -z "$last_time" ]] && return 0
    
    local diff=$((now - last_time))
    [[ $diff -ge $rate_limit ]]
}

get_severity_emoji() {
    case "$1" in
        critical) echo "🔴" ;;
        warning) echo "🟡" ;;
        info) echo "🔵" ;;
        *) echo "⚪" ;;
    esac
}

get_alert_type_emoji() {
    case "$1" in
        ddos) echo "🔥" ;;
        ram) echo "💾" ;;
        cpu) echo "🖥️" ;;
        disk) echo "💿" ;;
        service) echo "🔧" ;;
        security) echo "🔐" ;;
        ssl) echo "🔒" ;;
        *) echo "📢" ;;
    esac
}

list_alerts() {
    local limit="${1:-20}"
    echo "Recent Alerts:"
    echo ""
    tail -n "$limit" "$ALERT_LOG" 2>/dev/null || echo "No alerts"
}

clear_alerts() {
    > "$ALERT_LOG"
    rm -f "$LAST_ALERT_FILE"
    log_success "Alerts cleared"
}
