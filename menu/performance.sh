#!/bin/bash
#================================================
# Panda Script v2.0 - Performance Menu
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

performance_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║ ⚡ Performance Tuning                                    ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1. Auto-Tune All"
        echo "  2. Optimize Nginx"
        echo "  3. Optimize PHP"
        echo "  4. Optimize MariaDB"
        echo "  5. Kernel Tuning"
        echo "  6. ⚡ Cache Management"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                source "$PANDA_DIR/modules/nginx/install.sh"; nginx_optimize
                source "$PANDA_DIR/modules/php/install.sh"; configure_php
                source "$PANDA_DIR/modules/mariadb/install.sh"; optimize_mariadb
                source "$PANDA_DIR/security/hardening/kernel_harden.sh"; optimize_kernel_network
                pause
                ;;
            2) source "$PANDA_DIR/modules/nginx/install.sh"; nginx_optimize; pause ;;
            3) source "$PANDA_DIR/modules/php/install.sh"; configure_php; pause ;;
            4) source "$PANDA_DIR/modules/mariadb/install.sh"; optimize_mariadb; pause ;;
            5) source "$PANDA_DIR/security/hardening/kernel_harden.sh"; optimize_kernel_network; pause ;;
            6) source "$PANDA_DIR/modules/performance/cache.sh"; manage_cache ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    performance_menu
fi
