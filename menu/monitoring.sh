#!/bin/bash
source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

monitoring_menu() {
    while true; do
        clear
        print_header "📈 Monitoring & Alerts"
        echo "  1. Server Status"
        echo "  2. View Recent Alerts"
        echo "  3. Configure Telegram"
        echo "  4. Test Telegram Alert"
        echo "  5. Start Monitor Daemon"
        echo "  6. Stop Monitor Daemon"
        echo " 10. 🏥 Auto-Heal Services"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) source "$PANDA_DIR/monitoring/daemon/health_check.sh"; quick_status; pause ;;
            2) source "$PANDA_DIR/monitoring/alerts/alert_manager.sh"; list_alerts; pause ;;
            3) source "$PANDA_DIR/monitoring/alerts/telegram.sh"; configure_telegram; pause ;;
            4) source "$PANDA_DIR/monitoring/alerts/telegram.sh"; test_telegram; pause ;;
            5) source "$PANDA_DIR/monitoring/daemon/monitor_daemon.sh"; start_daemon; pause ;;
            6) source "$PANDA_DIR/monitoring/daemon/monitor_daemon.sh"; stop_daemon; pause ;;
            10) source "$PANDA_DIR/monitoring/auto_heal.sh"; auto_heal_services; pause ;;
            0) return ;;
        esac
    done
}
