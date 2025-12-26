#!/bin/bash
#================================================
# Panda Script v2.0 - System Menu
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

system_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║ ⚙️  System Configuration                                 ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1. 🛠️  Swap File Manager"
        echo "  2. 🧹 Junk File Cleaner"
        echo "  3. ⏰ Cronjob Manager"
        echo "  4. 📅 System Time & Hostname"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) source "$PANDA_DIR/modules/system/swap.sh"; manage_swap ;;
            2) source "$PANDA_DIR/modules/system/clean.sh"; clean_junk ;;
            3) source "$PANDA_DIR/modules/system/cron.sh"; manage_cron ;;
            4) system_info_menu ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}

system_info_menu() {
    clear
    echo "Current System Info:"
    uptime
    date
    hostname
    echo ""
    echo "  1. Set Hostname"
    echo "  2. Sync Time (NTP)"
    echo "  0. Back"
    echo ""
    read -p "Choice: " sic
    case $sic in
        1)
            read -p "Enter new hostname: " nh
            hostnamectl set-hostname "$nh"
            log_success "Hostname updated to $nh"
            pause
            ;;
        2)
            timedatectl set-ntp true
            log_success "NTP sync enabled."
            pause
            ;;
        *) return ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    system_menu
fi
