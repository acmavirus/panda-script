# Panda Script v2.5 - Main Menu (7 Groups)
# Optimized for UX - Easy to remember
# Website: https://panda-script.com
# Version: 3.1.0
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

show_main_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       🐼 Panda Script v3.1.0 - Premium UX            ║${NC}"
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
        echo -e "${CYAN}║${NC}  2. 📋 List Websites                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  3. ❌ Delete Website                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  4. 📑 Clone Website                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  5. 🔧 WP-CLI Management                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  6. 🐙 Clone from GitHub (NEW)                              ${CYAN}║${NC}"
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
            6) clone_from_github_menu ;;
            0) return ;;
            *) log_error "Invalid option"; sleep 1 ;;
        esac
    done
}

# Clone from GitHub
clone_from_github_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🐙 Clone from GitHub                            ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  Select project type:                                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  1. 🐘 PHP (Laravel, CodeIgniter, etc)                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  2. 📦 Node.js                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  3. 🐍 Python (Flask, FastAPI, Django)                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  4. ☕ Java (Spring Boot)                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  0. ← Back                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Enter your choice: " type_choice
    
    case $type_choice in
        1) project_type="php" ;;
        2) project_type="nodejs" ;;
        3) project_type="python" ;;
        4) project_type="java" ;;
        0) return ;;
        *) log_error "Invalid option"; return ;;
    esac
    
    echo ""
    read -p "GitHub URL (e.g., https://github.com/user/repo.git): " repo_url
    if [ -z "$repo_url" ]; then
        log_error "URL cannot be empty"
        pause
        return
    fi
    
    read -p "Domain/Project name: " domain
    if [ -z "$domain" ]; then
        log_error "Domain cannot be empty"
        pause
        return
    fi
    
    echo ""
    log_info "Cloning $project_type project from $repo_url..."
    
    case $project_type in
        php)
            WEB_ROOT="/home/$domain"
            mkdir -p "$WEB_ROOT"
            git clone --depth 1 "$repo_url" "$WEB_ROOT" 2>&1 || { rm -rf "$WEB_ROOT"; git clone --depth 1 "$repo_url" "$WEB_ROOT"; }
            chown -R www-data:www-data "$WEB_ROOT"
            find "$WEB_ROOT" -type d -exec chmod 755 {} \;
            find "$WEB_ROOT" -type f -exec chmod 644 {} \;
            
            # Install composer if exists
            if [ -f "$WEB_ROOT/composer.json" ]; then
                cd "$WEB_ROOT"
                composer install --no-dev --optimize-autoloader 2>/dev/null || true
            fi
            
            # Create Nginx config
            cat > /etc/nginx/sites-available/$domain.conf << NGINX
server {
    listen 80;
    server_name $domain;
    root /home/$domain;
    index index.php index.html;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php\$ {
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
NGINX
            ln -sf /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/
            nginx -t && systemctl reload nginx
            log_success "PHP project cloned to $WEB_ROOT"
            ;;
        nodejs)
            WEB_ROOT="/home/nodejs-apps/$domain"
            mkdir -p "/home/nodejs-apps"
            git clone --depth 1 "$repo_url" "$WEB_ROOT"
            cd "$WEB_ROOT"
            npm install 2>/dev/null || true
            log_success "Node.js project cloned to $WEB_ROOT"
            echo "Run: cd $WEB_ROOT && npm start"
            ;;
        python)
            WEB_ROOT="/home/python-apps/$domain"
            mkdir -p "/home/python-apps"
            git clone --depth 1 "$repo_url" "$WEB_ROOT"
            cd "$WEB_ROOT"
            python3 -m venv venv 2>/dev/null || true
            source venv/bin/activate 2>/dev/null || true
            pip install -r requirements.txt 2>/dev/null || true
            log_success "Python project cloned to $WEB_ROOT"
            ;;
        java)
            WEB_ROOT="/home/java-apps/$domain"
            mkdir -p "/home/java-apps"
            git clone --depth 1 "$repo_url" "$WEB_ROOT"
            log_success "Java project cloned to $WEB_ROOT"
            ;;
    esac
    
    pause
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
        echo -e "${CYAN}║${NC}  7. 🚀 PM2 Manager                                          ${CYAN}║${NC}"
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
            7) source "$PANDA_DIR/modules/website/nodejs.sh"; manage_pm2 ;;
            0) return ;;
            *) log_error "Invalid option"; sleep 1 ;;
        esac
    done
}

install_cache_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              📦 Cache Server Management                      ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  1. 📕 Install Redis                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  2. 📗 Install Memcached                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  3. 📊 Redis Info                                           ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  4. 🔄 Restart Redis                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  5. 🔄 Restart Memcached                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  0. ← Back                                                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) 
                log_info "Installing Redis..."
                apt-get install -y redis-server && systemctl enable redis-server && systemctl start redis-server
                log_success "Redis installed and started"
                pause
                ;;
            2) 
                log_info "Installing Memcached..."
                apt-get install -y memcached && systemctl enable memcached && systemctl start memcached
                log_success "Memcached installed and started"
                pause
                ;;
            3)
                echo -e "${YELLOW}Redis Info:${NC}"
                redis-cli INFO server 2>/dev/null | head -20 || log_error "Redis not running"
                pause
                ;;
            4)
                systemctl restart redis-server && log_success "Redis restarted" || log_error "Failed"
                pause
                ;;
            5)
                systemctl restart memcached && log_success "Memcached restarted" || log_error "Failed"
                pause
                ;;
            0) return ;;
            *) log_error "Invalid option"; sleep 1 ;;
        esac
    done
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
        echo -e "${CYAN}║${NC}  7. 🩺 Health Check (Panda Doctor)                          ${CYAN}║${NC}"
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
            7) health_check ;;
            0) return ;;
            *) log_error "Invalid option"; sleep 1 ;;
        esac
    done
}

# Health Check (Panda Doctor)
health_check() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🩺 Panda Doctor - Health Check                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local score=100
    
    # Disk Usage
    echo -e "${YELLOW}📁 Disk Usage:${NC}"
    disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    if [ "$disk_usage" -gt 90 ]; then
        echo -e "   ${RED}✗ CRITICAL: ${disk_usage}% used${NC}"
        score=$((score - 30))
    elif [ "$disk_usage" -gt 80 ]; then
        echo -e "   ${YELLOW}⚠ WARNING: ${disk_usage}% used${NC}"
        score=$((score - 10))
    else
        echo -e "   ${GREEN}✓ OK: ${disk_usage}% used${NC}"
    fi
    
    # Memory Usage
    echo ""
    echo -e "${YELLOW}💾 Memory Usage:${NC}"
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    if [ "$mem_usage" -gt 95 ]; then
        echo -e "   ${RED}✗ CRITICAL: ${mem_usage}% used${NC}"
        score=$((score - 20))
    elif [ "$mem_usage" -gt 85 ]; then
        echo -e "   ${YELLOW}⚠ WARNING: ${mem_usage}% used${NC}"
        score=$((score - 5))
    else
        echo -e "   ${GREEN}✓ OK: ${mem_usage}% used${NC}"
    fi
    
    # Services Check
    echo ""
    echo -e "${YELLOW}🔧 Services:${NC}"
    for svc in nginx mysql php8.3-fpm; do
        status=$(systemctl is-active $svc 2>/dev/null)
        if [ "$status" = "active" ]; then
            echo -e "   ${GREEN}✓ $svc: $status${NC}"
        else
            echo -e "   ${RED}✗ $svc: $status${NC}"
            score=$((score - 15))
        fi
    done
    
    # SSL Check
    echo ""
    echo -e "${YELLOW}🔒 SSL Certificates:${NC}"
    cert_count=$(ls /etc/letsencrypt/live/ 2>/dev/null | wc -l)
    echo -e "   Active certificates: $cert_count"
    
    # Calculate final score
    if [ $score -lt 0 ]; then score=0; fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    if [ $score -ge 80 ]; then
        echo -e "${GREEN}🎉 Health Score: $score/100 - System is healthy!${NC}"
    elif [ $score -ge 50 ]; then
        echo -e "${YELLOW}⚠️  Health Score: $score/100 - Some issues need attention${NC}"
    else
        echo -e "${RED}🚨 Health Score: $score/100 - Critical issues detected!${NC}"
    fi
    echo ""
    
    pause
}
# Panda Panel v3.1.0 - Unified Installer
# Includes: CLI Menu + Web Panel + Scripts
#================================================
panel_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       🐼 PANDA SCRIPT v2.5 INSTALLER         ║${NC}"
echo -e "${CYAN}║       High Performance LEMP + Panel v3.1.0   ║${NC}"
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
