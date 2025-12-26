#!/bin/bash
#================================================
# Panda Script v2.0 - Telegram Notifications
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

TELEGRAM_API="https://api.telegram.org/bot"

send_telegram_alert() {
    local severity="$1"
    local alert_type="$2"
    local message="$3"
    local hostname="$4"
    
    local bot_token=$(get_config telegram bot_token)
    local chat_id=$(get_config telegram chat_id)
    
    [[ -z "$bot_token" || "$bot_token" == "YOUR_BOT_TOKEN_HERE" ]] && return 1
    [[ -z "$chat_id" || "$chat_id" == "YOUR_CHAT_ID_HERE" ]] && return 1
    
    local severity_emoji=$(get_severity_emoji "$severity")
    local type_emoji=$(get_alert_type_emoji "$alert_type")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local text="🐼 *PANDA SCRIPT ALERT*
${severity_emoji} *${severity^^}*

*Server:* \`$hostname\`
*Time:* $timestamp

━━━━━━━━━━━━━━━━━━━━
${type_emoji} *${alert_type^^}*

$message
━━━━━━━━━━━━━━━━━━━━"

    curl -s -X POST "${TELEGRAM_API}${bot_token}/sendMessage" \
        -d "chat_id=$chat_id" \
        -d "text=$text" \
        -d "parse_mode=Markdown" \
        -d "disable_web_page_preview=true" &>/dev/null
    
    return $?
}

send_telegram_message() {
    local message="$1"
    local parse_mode="${2:-Markdown}"
    
    local bot_token=$(get_config telegram bot_token)
    local chat_id=$(get_config telegram chat_id)
    
    [[ -z "$bot_token" || "$bot_token" == "YOUR_BOT_TOKEN_HERE" ]] && return 1
    
    curl -s -X POST "${TELEGRAM_API}${bot_token}/sendMessage" \
        -d "chat_id=$chat_id" \
        -d "text=$message" \
        -d "parse_mode=$parse_mode" &>/dev/null
}

test_telegram() {
    local bot_token=$(get_config telegram bot_token)
    local chat_id=$(get_config telegram chat_id)
    
    if [[ -z "$bot_token" || "$bot_token" == "YOUR_BOT_TOKEN_HERE" ]]; then
        log_error "Telegram bot token not configured"
        return 1
    fi
    
    local response=$(curl -s "${TELEGRAM_API}${bot_token}/getMe")
    
    if echo "$response" | grep -q '"ok":true'; then
        log_success "Telegram bot connected"
        send_telegram_message "🐼 *Panda Script* - Test message successful!"
        return 0
    else
        log_error "Telegram connection failed"
        return 1
    fi
}

configure_telegram() {
    echo "Telegram Configuration"
    echo ""
    
    local bot_token=$(prompt "Enter Bot Token" "$(get_config telegram bot_token)")
    local chat_id=$(prompt "Enter Chat ID" "$(get_config telegram chat_id)")
    
    sed -i "s/^bot_token =.*/bot_token = $bot_token/" "${ALERTS_CONF}"
    sed -i "s/^chat_id =.*/chat_id = $chat_id/" "${ALERTS_CONF}"
    
    test_telegram
}
