#!/bin/bash
#================================================
# Panda Script v2.0 - SSH Hardening
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

SSHD_CONFIG="/etc/ssh/sshd_config"

harden_ssh() {
    log_info "Hardening SSH..."
    
    backup_file "$SSHD_CONFIG"
    
    # Basic hardening
    set_ssh_option "PermitRootLogin" "prohibit-password"
    set_ssh_option "PasswordAuthentication" "yes"
    set_ssh_option "MaxAuthTries" "5"
    set_ssh_option "MaxSessions" "3"
    set_ssh_option "ClientAliveInterval" "300"
    set_ssh_option "ClientAliveCountMax" "2"
    set_ssh_option "X11Forwarding" "no"
    set_ssh_option "AllowTcpForwarding" "no"
    set_ssh_option "PermitEmptyPasswords" "no"
    set_ssh_option "Protocol" "2"
    
    systemctl restart sshd
    log_success "SSH hardened"
}

set_ssh_option() {
    local option="$1"
    local value="$2"
    
    if grep -q "^#*$option" "$SSHD_CONFIG"; then
        sed -i "s/^#*$option.*/$option $value/" "$SSHD_CONFIG"
    else
        echo "$option $value" >> "$SSHD_CONFIG"
    fi
}

change_ssh_port() {
    local new_port="$1"
    
    [[ "$new_port" -lt 1 || "$new_port" -gt 65535 ]] && { log_error "Invalid port"; return 1; }
    
    backup_file "$SSHD_CONFIG"
    set_ssh_option "Port" "$new_port"
    
    # Update firewall
    source "${PANDA_DIR}/security/firewall/firewall.sh"
    firewall_allow_port "$new_port" "tcp"
    
    systemctl restart sshd
    log_success "SSH port changed to $new_port"
}

disable_root_login() {
    set_ssh_option "PermitRootLogin" "no"
    systemctl restart sshd
    log_success "Root login disabled"
}

enable_key_only() {
    set_ssh_option "PasswordAuthentication" "no"
    set_ssh_option "PubkeyAuthentication" "yes"
    systemctl restart sshd
    log_success "Key-only authentication enabled"
}

get_ssh_status() {
    echo "SSH Configuration:"
    echo ""
    
    local options=("Port" "PermitRootLogin" "PasswordAuthentication" "MaxAuthTries" "X11Forwarding")
    
    for opt in "${options[@]}"; do
        local value=$(grep "^$opt" "$SSHD_CONFIG" | awk '{print $2}')
        print_line "$opt" "${value:-default}"
    done
}
