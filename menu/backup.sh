#!/bin/bash
source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

backup_menu() {
    while true; do
        clear
        print_header "💾 Backup & Restore"
        echo "  1. Full Backup (All Sites + DBs)"
        echo "  2. Backup Single Website"
        echo "  3. Backup Single Database"
        echo "  4. List Backups"
        echo "  5. Restore from Backup"
        echo "  6. Cleanup Old Backups"
        echo "  7. ☁️  Cloud Backup (Rclone)"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        source "$PANDA_DIR/modules/backup/local.sh"
        
        case $choice in
            1) run_backup "all"; pause ;;
            2)
                local domain=$(prompt "Website domain")
                run_backup "$domain"
                pause
                ;;
            3)
                local db=$(prompt "Database name")
                backup_database "$db"
                pause
                ;;
            4) list_backups; pause ;;
            5)
                local file=$(prompt "Backup file path")
                restore_backup "$file"
                pause
                ;;
            6)
                local days=$(prompt "Keep backups newer than (days)" "7")
                cleanup_old_backups "$days"
                pause
                ;;
            0) return ;;
        esac
    done
}
