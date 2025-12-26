#!/bin/bash
#================================================
# Panda Script v2.0 - Auto-Heal Service
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

auto_heal_check() {
    local services=("nginx" "mariadb" "php8.3-fpm" "redis-server")
    
    for service in "${services[@]}"; do
        if systemctl list-units --full --all | grep -q "$service" && ! systemctl is-active --quiet "$service"; then
            log_warning "Service $service is down! Attempting auto-heal..."
            systemctl restart "$service"
            if systemctl is-active --quiet "$service"; then
                log_success "Service $service successfully restarted."
                # Future: Send Telegram notification
            else
                log_error "Failed to restart $service. Manual intervention needed."
            fi
        fi
    done
}

setup_auto_heal_cron() {
    local cron_cmd="* * * * * /opt/panda/monitoring/auto_heal.sh run >> /var/log/panda_auto_heal.log 2>&1"
    (crontab -l 2>/dev/null; echo "$cron_cmd") | sort -u | crontab -
    log_success "Auto-heal check scheduled every minute."
    pause
}

remove_auto_heal_cron() {
    crontab -l | grep -v "auto_heal.sh" | crontab -
    log_success "Auto-heal check removed."
    pause
}

if [[ "$1" == "run" ]]; then
    auto_heal_check
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # When called manually from menu
    echo "  1. Run Manual Check"
    echo "  2. Enable Auto-Heal (every minute)"
    echo "  3. Disable Auto-Heal"
    echo "  0. Back"
    read -p "Choice: " choice
    case $choice in
        1) auto_heal_check; pause ;;
        2) setup_auto_heal_cron ;;
        3) remove_auto_heal_cron ;;
        *) exit 0 ;;
    esac
fi
