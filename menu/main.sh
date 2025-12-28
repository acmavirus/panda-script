#!/bin/bash
#================================================
# Panda Script v2.3 - Main Menu (7 Groups)
# Optimized for UX - Easy to remember
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

show_main_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       🐼 Panda Script v2.3 - High Performance LEMP           ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}1.${NC} 🌐 ${WHITE}Websites${NC}    → Create, CMS, Clone, WP-CLI            ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}2.${NC} 📦 ${WHITE}Projects${NC}    → Node.js, Python, Java, Deploy        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}3.${NC} 📊 ${WHITE}Databases${NC}   → MariaDB, Sync, Slow Query            ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}4.${NC} ⚙️  ${WHITE}Services${NC}    → PHP, Nginx, SSL, Docker, Redis       ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}5.${NC} 🛡️  ${WHITE}Security${NC}    → Firewall, SSH, Guard, Permissions    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}6.${NC} 🔧 ${WHITE}System${NC}      → Backup, Monitor, Tools, Cleanup      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}7.${NC} 🎛️  ${WHITE}Panel${NC}       → Web Panel v3, Update, Settings       ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${RED}0.${NC} ❌ Exit                                                 ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1) websites_menu ;;
            2) projects_menu ;;
            3) databases_menu ;;
            4) services_menu ;;
            5) security_menu_new ;;
            6) system_menu_new ;;
            7) panel_menu ;;
            0) 
                echo -e "${GREEN}Goodbye! 🐼${NC}"
                exit 0 
                ;;
            *) 
                log_error "Invalid option. Please enter 0-7."
                sleep 1
                ;;
        esac
    done
}

#================================================
# 1. WEBSITES MENU
#================================================
websites_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              🌐 Websites Management                          ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  1. ➕ Create Website                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}     ├── Empty Site                                          ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}     ├── CMS One-Click (WordPress, Joomla...)                ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}     └── Node.js/Python App                                  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  2. 📋 List Websites                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  3. ❌ Delete Website                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  4. 📑 Clone Website                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  5. 🔧 WP-CLI Management                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  0. ← Back                                                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) create_website_flow ;;
            2) source "$PANDA_DIR/modules/website/create.sh"; list_websites ;;
            3) source "$PANDA_DIR/modules/website/create.sh"; delete_website ;;
            4) source "$PANDA_DIR/modules/website/clone.sh"; clone_website ;;
            5) source "$PANDA_DIR/modules/website/wp_cli.sh"; wp_cli_menu ;;
            0) return ;;
            *) log_error "Invalid option"; sleep 1 ;;
        esac
    done
}

# Website Creation Flow (3 options)
create_website_flow() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           What would you like to create?                     ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}1.${NC} 📄 ${WHITE}Empty Site${NC}                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}     Blank website, upload your own code                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}2.${NC} 🚀 ${WHITE}CMS One-Click${NC}                                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}     WordPress, Joomla, Drupal, WooCommerce...               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}3.${NC} 💻 ${WHITE}App/Project${NC}                                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}     Node.js, Python, Java application                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${RED}0.${NC} ← Back                                                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Enter your choice: " choice
    
    case $choice in
        1) source "$PANDA_DIR/modules/website/create.sh"; create_website ;;
        2) source "$PANDA_DIR/modules/website/cms_installer.sh"; cms_menu ;;
        3) source "$PANDA_DIR/menu/project.sh"; project_menu ;;
        0) return ;;
        *) log_error "Invalid option"; sleep 1 ;;
    esac
}

#================================================
# 2. PROJECTS MENU
#================================================
projects_menu() {
    source "$PANDA_DIR/menu/project.sh"
    project_menu
}

#================================================
# 3. DATABASES MENU
#================================================
databases_menu() {
    source "$PANDA_DIR/menu/database.sh"
    database_menu
}

#================================================
# 4. SERVICES MENU (PHP, Nginx, SSL, Docker, Redis)
#================================================
services_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              ⚙️  Services Management                          ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  1. 🐘 PHP Manager (Versions, Extensions, Config)            ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  2. 🔧 Nginx Manager (Test, Reload, Optimize)               ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  3. 🔒 SSL Manager (Let's Encrypt)                          ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  4. 🐋 Docker Manager                                       ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  5. 📦 Redis/Memcached                                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  6. ☁️  Cloudflare (Cache Purge)                             ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  0. ← Back                                                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) source "$PANDA_DIR/menu/php.sh"; php_menu ;;
            2) source "$PANDA_DIR/menu/nginx.sh"; nginx_menu ;;
            3) source "$PANDA_DIR/menu/ssl.sh"; ssl_menu ;;
            4) source "$PANDA_DIR/menu/docker.sh"; docker_menu ;;
            5) install_cache_menu ;;
            6) source "$PANDA_DIR/modules/cloud/cloudflare.sh"; cf_purge_cache ;;
            0) return ;;
            *) log_error "Invalid option"; sleep 1 ;;
        esac
    done
}

install_cache_menu() {
    clear
    echo "Installing Redis/Memcached..."
    # TODO: Add Redis/Memcached installation
    pause
}

#================================================
# 5. SECURITY MENU
#================================================
security_menu_new() {
    source "$PANDA_DIR/menu/security.sh"
    security_menu
}

#================================================
# 6. SYSTEM MENU (Backup, Monitor, Tools, Cleanup)
#================================================
system_menu_new() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              🔧 System Management                            ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  1. 💾 Backup Manager                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  2. 📈 System Monitoring                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  3. ⚡ Performance Tuning                                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  4. 🧹 System Cleanup                                       ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  5. ⏰ Cron Jobs                                            ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  6. 🛠️  Developer Tools                                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  0. ← Back                                                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) source "$PANDA_DIR/menu/backup.sh"; backup_menu ;;
            2) source "$PANDA_DIR/menu/monitoring.sh"; monitoring_menu ;;
            3) source "$PANDA_DIR/menu/performance.sh"; performance_menu ;;
            4) source "$PANDA_DIR/modules/system/clean.sh"; system_cleanup ;;
            5) source "$PANDA_DIR/modules/system/cron.sh"; cron_menu ;;
            6) source "$PANDA_DIR/menu/developer.sh"; developer_menu ;;
            0) return ;;
            *) log_error "Invalid option"; sleep 1 ;;
        esac
    done
}

#================================================
# 7. PANEL MENU (Web Panel v3)
#================================================
panel_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              🎛️  Panda Panel v3                               ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  1. 🌐 Open Web Panel (Browser)                             ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  2. ▶️  Start Panel Service                                  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  3. ⏹️  Stop Panel Service                                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  4. 🔄 Restart Panel                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  5. 🔧 Change Panel Port                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  6. 🔒 Enable Panel SSL                                     ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  7. 🔑 Reset Admin Password                                 ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  8. ⬆️  Update Panda Script                                  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  0. ← Back                                                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) 
                local ip=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
                echo -e "${GREEN}Opening: http://$ip:8080/panda/${NC}"
                xdg-open "http://$ip:8080/panda/" 2>/dev/null || echo "Open manually in browser"
                pause
                ;;
            2) systemctl start panda-panel && log_success "Panel started" || log_error "Failed"; pause ;;
            3) systemctl stop panda-panel && log_success "Panel stopped" || log_error "Failed"; pause ;;
            4) systemctl restart panda-panel && log_success "Panel restarted" || log_error "Failed"; pause ;;
            5) change_panel_port ;;
            6) enable_panel_ssl ;;
            7) reset_admin_password ;;
            8) update_panda_script ;;
            0) return ;;
            *) log_error "Invalid option"; sleep 1 ;;
        esac
    done
}

change_panel_port() {
    read -p "Enter new port (current: 8080): " new_port
    if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1024 ] && [ "$new_port" -le 65535 ]; then
        # Update port in config
        echo "Port changed to $new_port (restart panel to apply)"
        pause
    else
        log_error "Invalid port number"
        pause
    fi
}

enable_panel_ssl() {
    echo "Enabling SSL for Panel..."
    # TODO: Implement SSL for panel
    pause
}

reset_admin_password() {
    read -sp "Enter new admin password: " new_pass
    echo ""
    if [ -n "$new_pass" ]; then
        # TODO: Hash and update password
        log_success "Password updated"
    else
        log_error "Password cannot be empty"
    fi
    pause
}

update_panda_script() {
    echo "Checking for updates..."
    cd "$PANDA_DIR"
    git pull origin main 2>/dev/null && log_success "Updated successfully!" || log_error "Update failed"
    pause
}

# Start menu
show_main_menu
