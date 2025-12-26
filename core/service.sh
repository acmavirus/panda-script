#!/bin/bash
#================================================
# Panda Script v2.0 - Service Management
# Systemd service management
# Website: https://panda-script.com
#================================================

#------------------------------------------------
# Check if Systemd
#------------------------------------------------
is_systemd() {
    [[ -d /run/systemd/system ]]
}

#------------------------------------------------
# Service Start
#------------------------------------------------
service_start() {
    local service="$1"
    
    if is_systemd; then
        systemctl start "$service"
    else
        service "$service" start
    fi
    
    return $?
}

#------------------------------------------------
# Service Stop
#------------------------------------------------
service_stop() {
    local service="$1"
    
    if is_systemd; then
        systemctl stop "$service"
    else
        service "$service" stop
    fi
    
    return $?
}

#------------------------------------------------
# Service Restart
#------------------------------------------------
service_restart() {
    local service="$1"
    
    if is_systemd; then
        systemctl restart "$service"
    else
        service "$service" restart
    fi
    
    return $?
}

#------------------------------------------------
# Service Reload
#------------------------------------------------
service_reload() {
    local service="$1"
    
    if is_systemd; then
        systemctl reload "$service" 2>/dev/null || systemctl restart "$service"
    else
        service "$service" reload 2>/dev/null || service "$service" restart
    fi
    
    return $?
}

#------------------------------------------------
# Service Enable
#------------------------------------------------
service_enable() {
    local service="$1"
    
    if is_systemd; then
        systemctl enable "$service"
    else
        if command -v chkconfig &>/dev/null; then
            chkconfig "$service" on
        elif command -v update-rc.d &>/dev/null; then
            update-rc.d "$service" defaults
        fi
    fi
    
    return $?
}

#------------------------------------------------
# Service Disable
#------------------------------------------------
service_disable() {
    local service="$1"
    
    if is_systemd; then
        systemctl disable "$service"
    else
        if command -v chkconfig &>/dev/null; then
            chkconfig "$service" off
        elif command -v update-rc.d &>/dev/null; then
            update-rc.d "$service" remove
        fi
    fi
    
    return $?
}

#------------------------------------------------
# Service Status
#------------------------------------------------
service_status() {
    local service="$1"
    
    if is_systemd; then
        systemctl status "$service"
    else
        service "$service" status
    fi
    
    return $?
}

#------------------------------------------------
# Check if Service Active
#------------------------------------------------
service_is_active() {
    local service="$1"
    
    if is_systemd; then
        systemctl is-active --quiet "$service"
    else
        service "$service" status &>/dev/null
    fi
    
    return $?
}

#------------------------------------------------
# Check if Service Enabled
#------------------------------------------------
service_is_enabled() {
    local service="$1"
    
    if is_systemd; then
        systemctl is-enabled --quiet "$service" 2>/dev/null
    else
        if command -v chkconfig &>/dev/null; then
            chkconfig --list "$service" 2>/dev/null | grep -q ":on"
        else
            return 1
        fi
    fi
    
    return $?
}

#------------------------------------------------
# Check if Service Exists
#------------------------------------------------
service_exists() {
    local service="$1"
    
    if is_systemd; then
        systemctl list-unit-files "$service.service" &>/dev/null
    else
        [[ -f "/etc/init.d/$service" ]]
    fi
    
    return $?
}

#------------------------------------------------
# Get Service Status String
#------------------------------------------------
get_service_status() {
    local service="$1"
    
    if service_is_active "$service"; then
        echo "running"
    else
        echo "stopped"
    fi
}

#------------------------------------------------
# List All Services
#------------------------------------------------
list_services() {
    if is_systemd; then
        systemctl list-units --type=service --all
    else
        service --status-all 2>/dev/null
    fi
}

#------------------------------------------------
# List Running Services
#------------------------------------------------
list_running_services() {
    if is_systemd; then
        systemctl list-units --type=service --state=running
    fi
}

#------------------------------------------------
# Daemon Reload
#------------------------------------------------
daemon_reload() {
    if is_systemd; then
        systemctl daemon-reload
    fi
}

#------------------------------------------------
# Wait for Service
#------------------------------------------------
wait_for_service() {
    local service="$1"
    local timeout="${2:-30}"
    local count=0
    
    while ! service_is_active "$service" && [[ $count -lt $timeout ]]; do
        sleep 1
        ((count++))
    done
    
    service_is_active "$service"
}

#------------------------------------------------
# Restart All Panda Services
#------------------------------------------------
restart_all_services() {
    log_info "Restarting services..."
    
    local services=("nginx" "php-fpm" "php8.3-fpm" "php8.2-fpm" "mariadb" "mysql")
    
    for service in "${services[@]}"; do
        if service_exists "$service" && service_is_active "$service"; then
            log_info "Restarting $service..."
            service_restart "$service"
        fi
    done
    
    log_success "Services restarted"
}

#------------------------------------------------
# LEMP Service Management
#------------------------------------------------
lemp_start() {
    service_start nginx
    service_start php-fpm 2>/dev/null || service_start php8.3-fpm 2>/dev/null || service_start php8.2-fpm
    service_start mariadb 2>/dev/null || service_start mysql
}

lemp_stop() {
    service_stop nginx
    service_stop php-fpm 2>/dev/null || service_stop php8.3-fpm 2>/dev/null || service_stop php8.2-fpm
    service_stop mariadb 2>/dev/null || service_stop mysql
}

lemp_restart() {
    service_restart nginx
    service_restart php-fpm 2>/dev/null || service_restart php8.3-fpm 2>/dev/null || service_restart php8.2-fpm
    service_restart mariadb 2>/dev/null || service_restart mysql
}

lemp_status() {
    echo "LEMP Stack Status:"
    echo ""
    print_status "Nginx" "$(get_service_status nginx)"
    
    for php in php-fpm php8.4-fpm php8.3-fpm php8.2-fpm php8.1-fpm; do
        if service_exists "$php"; then
            print_status "PHP-FPM" "$(get_service_status $php)"
            break
        fi
    done
    
    if service_exists mariadb; then
        print_status "MariaDB" "$(get_service_status mariadb)"
    elif service_exists mysql; then
        print_status "MySQL" "$(get_service_status mysql)"
    fi
}

#------------------------------------------------
# Create Systemd Service
#------------------------------------------------
create_systemd_service() {
    local name="$1"
    local description="$2"
    local exec_start="$3"
    local user="${4:-root}"
    
    cat > "/etc/systemd/system/${name}.service" << EOF
[Unit]
Description=$description
After=network.target

[Service]
Type=simple
User=$user
ExecStart=$exec_start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    daemon_reload
    service_enable "$name"
}
