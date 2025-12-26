#!/bin/bash
source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

php_menu() {
    while true; do
        clear
        print_header "🐘 PHP Management"
        echo "  1. PHP Status"
        echo "  2. Install PHP Version"
        echo "  3. Switch PHP Version"
        echo "  4. Restart PHP-FPM"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        source "$PANDA_DIR/modules/php/install.sh"
        
        case $choice in
            1) php_status; pause ;;
            2)
                local ver=$(prompt "PHP version (8.2/8.3/8.4)" "8.3")
                php_install "$ver"
                pause
                ;;
            3)
                local ver=$(prompt "Switch to version")
                switch_php_version "$ver"
                pause
                ;;
            4)
                systemctl restart php*-fpm
                log_success "PHP-FPM restarted"
                pause
                ;;
            0) return ;;
        esac
    done
}

nginx_menu() {
    while true; do
        clear
        print_header "🔧 Nginx Management"
        echo "  1. Nginx Status"
        echo "  2. Restart Nginx"
        echo "  3. Test Configuration"
        echo "  4. Optimize Nginx"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        source "$PANDA_DIR/modules/nginx/install.sh"
        
        case $choice in
            1) nginx_status; pause ;;
            2) systemctl restart nginx; log_success "Nginx restarted"; pause ;;
            3) nginx -t; pause ;;
            4) nginx_optimize; pause ;;
            0) return ;;
        esac
    done
}

system_menu() {
    while true; do
        clear
        print_header "⚙️ System Configuration"
        echo "  1. System Info"
        echo "  2. Set Timezone"
        echo "  3. Change SSH Port"
        echo "  4. Restart All Services"
        echo "  5. Update Panda Script"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                get_os_info
                echo ""
                get_cpu_info
                get_memory_info
                pause
                ;;
            2)
                local tz=$(prompt "Timezone" "Asia/Ho_Chi_Minh")
                timedatectl set-timezone "$tz"
                log_success "Timezone set to $tz"
                pause
                ;;
            3)
                local port=$(prompt "New SSH port")
                source "$PANDA_DIR/security/hardening/ssh_harden.sh"
                change_ssh_port "$port"
                pause
                ;;
            4) restart_all_services; pause ;;
            5) bash "$PANDA_DIR/../update"; pause ;;
            0) return ;;
        esac
    done
}

performance_menu() {
    while true; do
        clear
        print_header "⚡ Performance Tuning"
        echo "  1. Auto-Tune All"
        echo "  2. Optimize Nginx"
        echo "  3. Optimize PHP"
        echo "  4. Optimize MariaDB"
        echo "  5. Kernel Tuning"
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
            0) return ;;
        esac
    done
}
