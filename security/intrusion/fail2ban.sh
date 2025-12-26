#!/bin/bash
#================================================
# Panda Script v2.0 - fail2ban Management
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_fail2ban() {
    log_info "Installing fail2ban..."
    pkg_install fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    log_success "fail2ban installed"
}

configure_fail2ban() {
    log_info "Configuring fail2ban..."
    
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 5

[nginx-botsearch]
enabled = true
filter = nginx-botsearch
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 604800

[nginx-badbots]
enabled = true
filter = nginx-badbots
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 604800
EOF

    systemctl restart fail2ban
    log_success "fail2ban configured"
}

create_nginx_filters() {
    # Bad bots filter
    cat > /etc/fail2ban/filter.d/nginx-badbots.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST|HEAD).*HTTP.*" .* "(.*MJ12bot|.*AhrefsBot|.*SemrushBot|.*DotBot|.*BLEXBot).*"$
ignoreregex =
EOF

    # Bot search filter
    cat > /etc/fail2ban/filter.d/nginx-botsearch.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST|HEAD) .*(wp-login|xmlrpc|wp-admin|phpmyadmin|admin|setup|install).*".*$
ignoreregex =
EOF

    systemctl restart fail2ban
}

fail2ban_status() {
    fail2ban-client status
}

fail2ban_banned_list() {
    local jail="${1:-sshd}"
    fail2ban-client status "$jail" | grep "Banned IP list"
}

fail2ban_ban() {
    local ip="$1"
    local jail="${2:-sshd}"
    fail2ban-client set "$jail" banip "$ip"
    log_info "Banned $ip in $jail"
}

fail2ban_unban() {
    local ip="$1"
    local jail="${2:-sshd}"
    fail2ban-client set "$jail" unbanip "$ip"
    log_info "Unbanned $ip from $jail"
}

fail2ban_unban_all() {
    local jail="${1:-sshd}"
    fail2ban-client set "$jail" unbanip --all 2>/dev/null
    log_info "Unbanned all from $jail"
}
