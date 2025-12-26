#!/bin/bash
#================================================
# Panda Script v2.0 - Cache Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

manage_cache() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ ⚡ Cache Management                                      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "Services Status:"
    check_service_status redis-server
    check_service_status memcached
    echo ""
    
    echo "  1. Install Redis"
    echo "  2. Install Memcached"
    echo "  3. PHP OpCache Status (CLI)"
    echo "  4. Flush PHP OpCache"
    echo "  0. Back"
    echo ""
    read -p "Choice: " choice
    
    case $choice in
        1) install_redis ;;
        2) install_memcached ;;
        3) show_opcache_status ;;
        4) flush_opcache ;;
        0) return ;;
    esac
}

install_redis() {
    log_info "Installing Redis..."
    apt-get update
    apt-get install -y redis-server
    systemctl enable redis-server
    systemctl start redis-server
    log_success "Redis installed and started!"
    pause
}

install_memcached() {
    log_info "Installing Memcached..."
    apt-get update
    apt-get install -y memcached
    systemctl enable memcached
    systemctl start memcached
    log_success "Memcached installed and started!"
    pause
}

show_opcache_status() {
    if command -v php &>/dev/null; then
        php -r "print_r(opcache_get_status(false));" | head -n 20
    else
        log_error "PHP not found."
    fi
    pause
}

flush_opcache() {
    log_info "Flushing PHP OpCache..."
    systemctl restart php*-fpm
    log_success "OpCache flushed by restarting PHP-FPM."
    pause
}

check_service_status() {
    local service="$1"
    if systemctl is-active --quiet "$service"; then
        echo -e "  • $service: ${GREEN}Active${NC}"
    else
        echo -e "  • $service: ${RED}Inactive${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    manage_cache
fi
