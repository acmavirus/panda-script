#!/bin/bash
#================================================
# Panda Script v3.1 - WordPress Security Scanners & Hardeners
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

wp_security_menu() {
    while true; do
        clear
        print_header "🛡️  WordPress Security"
        echo "  1. 🔍  Full Security Scan (All sites)"
        echo "  2. 🔒  Fix Config Permissions (640)"
        echo "  3. 🚫  Block xmlrpc.php (All sites)"
        echo "  4. 🧹  Remove Debug Logs"
        echo "  5. 🛡️   Install WordPress Fail2Ban Jails"
        echo "  6. 🩹  Auto-Fix All WP Sites (Scan + Harden)"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) scan_all_wp_sites; pause ;;
            2) fix_wp_config_permissions; pause ;;
            3) block_xmlrpc_all; pause ;;
            4) remove_wp_debug_logs; pause ;;
            5) source "$PANDA_DIR/security/wp_fail2ban.sh"; harden_wordpress_security ;;
            6) auto_harden_all_wp; pause ;;
            0) return ;;
        esac
    done
}

scan_all_wp_sites() {
    log_info "Scanning all WordPress sites in /home..."
    echo "=========================================="
    
    for d in /home/*/; do
        if [ -f "${d}wp-config.php" ]; then
            echo "SITE: $d"
            
            # Version
            local ver=$(grep "wp_version =" "${d}wp-includes/version.php" | cut -d"'" -f2)
            echo "[i] Version: $ver"
            
            # Permissions
            local perms=$(stat -c "%a" "${d}wp-config.php")
            echo "[i] wp-config.php Perms: $perms"
            if [ "$perms" -gt 640 ]; then
                echo "    [!] WARNING: Loose permissions!"
            fi
            
            # Debug log
            if [ -f "${d}wp-content/debug.log" ]; then
                echo "    [!] WARNING: Debug log exposed at wp-content/debug.log"
            fi
            
            # xmlrpc
            if [ -f "${d}xmlrpc.php" ]; then
                local xperms=$(stat -c "%a" "${d}xmlrpc.php")
                if [ "$xperms" != "000" ]; then
                    echo "    [i] xmlrpc.php is active"
                fi
            fi

            # PHP in Uploads
            local shells=$(find "${d}wp-content/uploads" -name "*.php" 2>/dev/null | wc -l)
            if [ "$shells" -gt 0 ]; then
                echo "    [CRITICAL] $shells PHP file(s) found in uploads!"
            fi
            echo "------------------------------------------"
        fi
    done
}

fix_wp_config_permissions() {
    log_info "Fixing wp-config.php permissions to 640..."
    find /home/*/ -name "wp-config.php" -exec chmod 640 {} \;
    log_success "Applied to all sites."
}

block_xmlrpc_all() {
    log_info "Blocking xmlrpc.php (chmod 000) on all sites..."
    find /home/*/ -name "xmlrpc.php" -exec chmod 000 {} \;
    log_success "Applied to all sites."
}

remove_wp_debug_logs() {
    log_info "Removing wp-content/debug.log files..."
    find /home/*/wp-content/ -name "debug.log" -exec rm -f {} \;
    log_success "All debug logs removed."
}

auto_harden_all_wp() {
    log_info "Starting Auto-Hardening process..."
    remove_wp_debug_logs
    fix_wp_config_permissions
    block_xmlrpc_all
    log_success "Auto-Hardening completed for all sites."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    wp_security_menu
fi
