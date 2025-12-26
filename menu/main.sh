#!/bin/bash
#================================================
# Panda Script v2.0 - Main Menu
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

show_main_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║          🐼 Panda Script v2.2 - Server Management            ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  1. 🌐 Website Management                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  2. 📊 Database Management                                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  3. 🔒 SSL/HTTPS Management                                  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  4. 💾 Backup & Restore                                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  5. 🐘 PHP Management                                        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  6. 🔧 Nginx Management                                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  7. 📈 Monitoring & Alerts                                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  8. 🛡️  Security Center                                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  9. ⚡ Performance Tuning                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  10. ⚙️  System Configuration                                ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  11. 🐋 Docker Management                                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  12. ☁️  Cloudflare Management                                 ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  13. 👨‍💻 Developer Tools (DevXP)                                ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  0. ❌ Exit                                                   ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) source "$PANDA_DIR/menu/website.sh"; website_menu ;;
            2) source "$PANDA_DIR/menu/database.sh"; database_menu ;;
            3) source "$PANDA_DIR/menu/ssl.sh"; ssl_menu ;;
            4) source "$PANDA_DIR/menu/backup.sh"; backup_menu ;;
            5) source "$PANDA_DIR/menu/php.sh"; php_menu ;;
            6) source "$PANDA_DIR/menu/nginx.sh"; nginx_menu ;;
            7) source "$PANDA_DIR/menu/monitoring.sh"; monitoring_menu ;;
            8) source "$PANDA_DIR/menu/security.sh"; security_menu ;;
            9) source "$PANDA_DIR/menu/performance.sh"; performance_menu ;;
            10) source "$PANDA_DIR/menu/system.sh"; system_menu ;;
            11) source "$PANDA_DIR/menu/docker.sh"; docker_menu ;;
            12) source "$PANDA_DIR/modules/cloud/cloudflare.sh"; cf_purge_cache ;;
            13) source "$PANDA_DIR/menu/developer.sh"; developer_menu ;;
            0) 
                echo "Goodbye! 🐼"
                exit 0 
                ;;
            *) 
                log_error "Invalid option"
                pause 
                ;;
        esac
    done
}
