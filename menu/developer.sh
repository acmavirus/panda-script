#!/bin/bash
#================================================
# Panda Script v2.3 - Developer Tools Menu
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

developer_menu() {
    while true; do
        clear
        print_header "👨‍💻 Developer Tools (DevXP)"
        echo "  1. 🚀 Simple Deployment (git pull + build)"
        echo "  2. 🔗 Webhook Setup (GitHub/GitLab)"
        echo "  3. 🔍 Debug Multi-Log Tailer"
        echo "  4. 📉 MySQL Slow Query Monitor"
        echo "  5. 🖼️ Media & Image Optimization"
        echo "  6. 🗄️ Database Sync & Tools"
        echo "  7. 🔀 Cloudflare Tunneling (Public Preview)"
        echo "  8. 🔄 Deployment Workflow (Auto-Deploy)"
        echo "  0. Back"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) 
                local domain=$(prompt "Enter domain to deploy")
                source "$PANDA_DIR/modules/website/deploy.sh"; deploy_site "$domain"
                pause
                ;;
            2)
                local domain=$(prompt "Enter domain for Webhook")
                source "$PANDA_DIR/modules/website/webhook.sh"; setup_webhook "$domain"
                ;;
            3)
                local domain=$(prompt "Enter domain for Debug (blank for global)")
                source "$PANDA_DIR/monitoring/debug.sh"; tail_logs "$domain"
                ;;
            4) source "$PANDA_DIR/modules/mariadb/slow_query.sh"; slow_query_menu ;;
            5) source "$PANDA_DIR/modules/system/optimize.sh"; optimization_menu ;;
            6) source "$PANDA_DIR/modules/mariadb/sync.sh"; sync_menu ;;
            7) source "$PANDA_DIR/modules/cloud/tunnel.sh"; tunnel_menu ;;
            8) source "$PANDA_DIR/modules/deploy/workflow.sh"; deployment_workflow_menu ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    developer_menu
fi
