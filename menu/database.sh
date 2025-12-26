#!/bin/bash
source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

database_menu() {
    while true; do
        clear
        print_header "📊 Database Management"
        echo "  1. Create Database"
        echo "  2. Delete Database"
        echo "  3. List Databases"
        echo "  4. Backup Database"
        echo "  5. Restore Database"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                source "$PANDA_DIR/modules/mariadb/install.sh"
                local db_name=$(prompt "Database name")
                create_database "$db_name"
                pause
                ;;
            2)
                source "$PANDA_DIR/modules/mariadb/install.sh"
                local db_name=$(prompt "Database to delete")
                delete_database "$db_name"
                pause
                ;;
            3)
                source "$PANDA_DIR/modules/mariadb/install.sh"
                list_databases
                pause
                ;;
            4)
                source "$PANDA_DIR/modules/backup/local.sh"
                local db_name=$(prompt "Database to backup")
                backup_database "$db_name"
                pause
                ;;
            5)
                source "$PANDA_DIR/modules/backup/local.sh"
                local file=$(prompt "Backup file path")
                restore_backup "$file"
                pause
                ;;
            0) return ;;
        esac
    done
}
