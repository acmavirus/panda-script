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
        echo "  6. Configure MySQL Credentials"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        source "$PANDA_DIR/modules/mariadb/install.sh"
        
        case $choice in
            1)
                local db_name=$(prompt "Database name")
                create_database "$db_name"
                pause
                ;;
            2)
                local db_name=$(prompt "Database to delete")
                delete_database "$db_name"
                pause
                ;;
            3)
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
            6)
                configure_mysql_credentials
                pause
                ;;
            0) return ;;
        esac
    done
}
