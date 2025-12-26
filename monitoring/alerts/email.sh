#!/bin/bash
#================================================
# Panda Script v2.0 - Email Notifications
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

send_email_alert() {
    local severity="$1"
    local alert_type="$2"
    local message="$3"
    local hostname="$4"
    
    local smtp_host=$(get_config email smtp_host)
    local smtp_port=$(get_config email smtp_port)
    local smtp_user=$(get_config email smtp_user)
    local smtp_pass=$(get_config email smtp_pass)
    local from_addr=$(get_config email from_address)
    local to_addr=$(get_config email to_addresses)
    
    [[ -z "$to_addr" ]] && return 1
    
    local subject="[${severity^^}] Panda Script Alert - $hostname"
    local body="Panda Script Alert

Severity: ${severity^^}
Type: ${alert_type^^}
Server: $hostname
Time: $(date '+%Y-%m-%d %H:%M:%S')

Message:
$message
"

    if command -v mail &>/dev/null; then
        echo "$body" | mail -s "$subject" "$to_addr"
    elif command -v sendmail &>/dev/null; then
        echo -e "Subject: $subject\nFrom: $from_addr\nTo: $to_addr\n\n$body" | sendmail -t
    elif command -v curl &>/dev/null && [[ -n "$smtp_host" ]]; then
        curl -s --url "smtp://$smtp_host:$smtp_port" \
            --mail-from "$from_addr" \
            --mail-rcpt "$to_addr" \
            -u "$smtp_user:$smtp_pass" \
            -T <(echo -e "Subject: $subject\nFrom: $from_addr\nTo: $to_addr\n\n$body") \
            --ssl-reqd &>/dev/null
    fi
}

test_email() {
    local to_addr=$(get_config email to_addresses)
    [[ -z "$to_addr" ]] && { log_error "Email not configured"; return 1; }
    
    send_email_alert "info" "test" "Test email from Panda Script" "$(hostname)"
    log_success "Test email sent to $to_addr"
}
