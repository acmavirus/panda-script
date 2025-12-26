#!/bin/bash
#================================================
# Panda Script v2.0 - SSH Port Changer
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

change_ssh_port() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ 🔒 Change SSH Port                                     ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    local current_port=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')
    [[ -z "$current_port" ]] && current_port=22
    
    echo "Current SSH Port: $current_port"
    echo ""
    read -p "Enter new SSH port (1024-65535): " new_port
    
    if [[ ! "$new_port" =~ ^[0-9]+$ ]] || [[ "$new_port" -lt 1024 ]] || [[ "$new_port" -gt 65535 ]]; then
        log_error "Invalid port! Please use a number between 1024 and 65535."
        pause
        return
    fi
    
    if [[ "$new_port" == "$current_port" ]]; then
        log_warning "New port is the same as the current port."
        pause
        return
    fi
    
    echo ""
    log_warning "CAUTION: Changing SSH port can lock you out if not configured correctly."
    log_warning "Panda will automatically update the firewall (UFW)."
    if ! confirm "Proceed with changing port to $new_port?"; then
        return
    fi
    
    # Allow new port in UFW
    log_info "Allowing port $new_port in firewall..."
    ufw allow "$new_port"/tcp &>/dev/null
    
    # Update sshd_config
    log_info "Updating SSH configuration..."
    if grep -q "^Port " /etc/ssh/sshd_config; then
        sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
    else
        echo "Port $new_port" >> /etc/ssh/sshd_config
    fi
    
    # Restart SSH
    log_info "Restarting SSH service..."
    systemctl restart ssh || systemctl restart sshd
    
    log_success "SSH Port changed to $new_port!"
    log_important "DO NOT CLOSE THIS TERMINAL YET."
    log_important "Open a new terminal and try to connect using: ssh root@$(get_ip) -p $new_port"
    log_important "If it works, you can safely close this session."
    
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    change_ssh_port
fi
