#!/bin/bash
#================================================
# Panda Script v2.0 - Cronjob Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

manage_cron() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ ⏰ Cronjob Manager                                     ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "Current Cronjobs for $(whoami):"
    crontab -l 2>/dev/null || echo "(None)"
    echo ""
    
    echo "  1. Add New Cronjob"
    echo "  2. Remove All Cronjobs"
    echo "  0. Back"
    echo ""
    read -p "Enter choice: " choice
    
    case $choice in
        1) add_cron ;;
        2) delete_all_cron ;;
        0) return ;;
        *) manage_cron ;;
    esac
}

add_cron() {
    echo ""
    echo "Example: 0 0 * * * /path/to/script.sh"
    read -p "Enter cron expression and command: " cron_line
    
    if [[ -z "$cron_line" ]]; then
        return
    fi
    
    (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
    log_success "Cronjob added!"
    pause
}

delete_all_cron() {
    if confirm "Are you sure you want to remove ALL cronjobs for this user?"; then
        crontab -r 2>/dev/null
        log_success "All cronjobs removed."
    fi
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    manage_cron
fi
