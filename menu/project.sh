#!/bin/bash
#================================================
# Panda Script v2.3 - Project Manager Menu
# Central hub for all project types
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

project_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║ 📦 Project Manager                                       ║"
        echo "╠══════════════════════════════════════════════════════════╣"
        echo "║ Create, manage, and deploy applications with ease        ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  Select Project Type:"
        echo ""
        echo "  1. 🟢 Node.js Projects (PM2 + Express/Next.js/NestJS)"
        echo "  2. 🐍 Python Projects (Virtualenv + Flask/Django/FastAPI)"
        echo "  3. ☕ Java Projects (Spring Boot + Maven/Gradle)"
        echo "  4. 🐘 PHP Projects (Laravel/Symfony/WordPress)"
        echo "  5. 🚀 One-Click CMS (WordPress/Joomla/Drupal...)"
        echo ""
        echo "  Deployment:"
        echo ""
        echo "  6. 🔄 Deployment Workflow (GitHub Auto-Deploy)"
        echo ""
        echo "  0. Back to Main Menu"
        echo ""
        read -p "Select option: " choice
        
        case $choice in
            1) source "$PANDA_DIR/modules/project/nodejs.sh"; nodejs_project_menu ;;
            2) source "$PANDA_DIR/modules/project/python.sh"; python_project_menu ;;
            3) source "$PANDA_DIR/modules/project/java.sh"; java_project_menu ;;
            4) source "$PANDA_DIR/menu/website.sh"; website_menu ;;
            5) source "$PANDA_DIR/modules/website/cms_installer.sh"; cms_menu ;;
            6) source "$PANDA_DIR/modules/deploy/workflow.sh"; deployment_workflow_menu ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    project_menu
fi
