#!/bin/bash
#================================================
# Panda Script v2.0 - WordPress Fail2Ban Jails
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

harden_wordpress_security() {
    log_info "Hardening WordPress Security with Fail2Ban..."
    
    if ! command -v fail2ban-client &>/dev/null; then
        log_error "Fail2Ban not installed. Install it via Security Center first."
        return 1
    fi
    
    # 1. Create WP Login Filter
    cat > /etc/fail2ban/filter.d/wordpress-login.conf << EOF
[Definition]
failregex = ^<HOST> .* "POST /wp-login.php
            ^<HOST> .* "POST /xmlrpc.php
ignoreregex =
EOF

    # 2. Add Jail Config
    cat > /etc/fail2ban/jail.d/wordpress.conf << EOF
[wordpress-login]
enabled = true
port = http,https
filter = wordpress-login
logpath = /var/www/*/logs/access.log
maxretry = 5
findtime = 600
bantime = 3600
EOF

    systemctl restart fail2ban
    log_success "WordPress Fail2Ban jails added and active."
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    harden_wordpress_security
fi
