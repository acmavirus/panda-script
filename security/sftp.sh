#!/bin/bash
#================================================
# Panda Script v2.0 - SFTP User Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

create_sftp_user() {
    local domain="$1"
    local sftp_user="$2"
    local sftp_pass="$3"
    
    [[ -z "$domain" ]] || [[ -z "$sftp_user" ]] && { log_error "Domain and SFTP user required"; return 1; }
    
    if [[ ! -d "/home/$domain" ]]; then
        log_error "Domain directory /home/$domain doesn't exist."
        return 1
    fi
    
    log_info "Creating SFTP user: $sftp_user for $domain"
    
    # Create group if not exists
    groupadd sftp_users 2>/dev/null
    
    # Create user with jail
    useradd -g sftp_users -d "/home/$domain" -s /sbin/nologin "$sftp_user"
    echo "$sftp_user:$sftp_pass" | chpasswd
    
    # Secure home for chroot (must be owned by root)
    chown root:root "/home/$domain"
    chmod 755 "/home/$domain"
    
    # Ensure public folder is owned by user
    chown -R "$sftp_user:sftp_users" "/home/$domain/public"
    
    # Update SSH Config for SFTP Chroot if not already done
    if ! grep -q "Match Group sftp_users" /etc/ssh/sshd_config; then
        cat >> /etc/ssh/sshd_config << EOF

Match Group sftp_users
    ChrootDirectory %h
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF
        systemctl restart ssh
    fi
    
    log_success "SFTP user $sftp_user created and jailed to /home/$domain"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_sftp_user "$1" "$2" "$3"
fi
