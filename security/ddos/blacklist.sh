#!/bin/bash
#================================================
# Panda Script v2.0 - IP Blacklist Management
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

BLACKLIST_FILE="${PANDA_DATA_DIR:-/opt/panda/data}/blacklist.txt"

add_to_blacklist() {
    local ip="$1"
    local reason="${2:-manual}"
    local permanent="${3:-0}"
    
    is_valid_ip "$ip" || { log_error "Invalid IP: $ip"; return 1; }
    
    echo "$ip" >> "$BLACKLIST_FILE"
    sort -u "$BLACKLIST_FILE" -o "$BLACKLIST_FILE"
    
    source "${PANDA_DIR}/security/firewall/firewall.sh"
    firewall_block_ip "$ip"
    
    db_query "INSERT OR REPLACE INTO blocked_ips (ip_address, reason, permanent) VALUES ('$ip', '$reason', $permanent)"
    
    log_success "Added to blacklist: $ip"
}

remove_from_blacklist() {
    local ip="$1"
    
    sed -i "/^$ip$/d" "$BLACKLIST_FILE" 2>/dev/null
    
    source "${PANDA_DIR}/security/firewall/firewall.sh"
    firewall_unblock_ip "$ip"
    
    db_query "DELETE FROM blocked_ips WHERE ip_address='$ip'"
    
    log_success "Removed from blacklist: $ip"
}

list_blacklist() {
    echo "Blacklisted IPs:"
    echo ""
    
    if [[ -f "$BLACKLIST_FILE" && -s "$BLACKLIST_FILE" ]]; then
        cat "$BLACKLIST_FILE"
    else
        echo "No IPs in blacklist"
    fi
}

import_blacklist() {
    local file="$1"
    
    [[ -f "$file" ]] || { log_error "File not found: $file"; return 1; }
    
    local count=0
    while read -r ip; do
        [[ -z "$ip" || "$ip" =~ ^# ]] && continue
        add_to_blacklist "$ip" "imported"
        ((count++))
    done < "$file"
    
    log_success "Imported $count IPs"
}

export_blacklist() {
    local file="${1:-blacklist_export.txt}"
    cp "$BLACKLIST_FILE" "$file"
    log_success "Exported to: $file"
}

apply_blacklist() {
    log_info "Applying blacklist..."
    
    source "${PANDA_DIR}/security/firewall/firewall.sh"
    
    while read -r ip; do
        [[ -z "$ip" || "$ip" =~ ^# ]] && continue
        firewall_block_ip "$ip"
    done < "$BLACKLIST_FILE"
    
    log_success "Blacklist applied"
}

update_external_blacklists() {
    log_info "Updating external blacklists..."
    
    local lists=(
        "https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt"
    )
    
    for url in "${lists[@]}"; do
        curl -s "$url" 2>/dev/null | grep -v "^#" | awk '{print $1}' >> "$BLACKLIST_FILE"
    done
    
    sort -u "$BLACKLIST_FILE" -o "$BLACKLIST_FILE"
    log_success "External blacklists updated"
}
