#!/bin/bash
#================================================
# Panda Script v2.0 - IP Whitelist Management
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

WHITELIST_FILE="${PANDA_DATA_DIR:-/opt/panda/data}/whitelist.txt"

add_to_whitelist() {
    local ip="$1"
    
    is_valid_ip "$ip" || { log_error "Invalid IP: $ip"; return 1; }
    
    echo "$ip" >> "$WHITELIST_FILE"
    sort -u "$WHITELIST_FILE" -o "$WHITELIST_FILE"
    
    log_success "Added to whitelist: $ip"
}

remove_from_whitelist() {
    local ip="$1"
    sed -i "/^$ip$/d" "$WHITELIST_FILE" 2>/dev/null
    log_success "Removed from whitelist: $ip"
}

is_whitelisted() {
    local ip="$1"
    [[ -f "$WHITELIST_FILE" ]] && grep -q "^$ip$" "$WHITELIST_FILE"
}

list_whitelist() {
    echo "Whitelisted IPs:"
    echo ""
    
    if [[ -f "$WHITELIST_FILE" && -s "$WHITELIST_FILE" ]]; then
        cat "$WHITELIST_FILE"
    else
        echo "No IPs in whitelist"
    fi
}

init_whitelist() {
    # Add common safe IPs
    local safe_ips=(
        "127.0.0.1"
        "::1"
    )
    
    # Add server's own IPs
    safe_ips+=("$(get_private_ip)")
    safe_ips+=("$(get_public_ip)")
    
    for ip in "${safe_ips[@]}"; do
        [[ -n "$ip" && "$ip" != "unknown" ]] && add_to_whitelist "$ip"
    done
}
