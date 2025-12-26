#!/bin/bash
#================================================
# Panda Script v2.0 - Docker Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_docker() {
    log_info "Installing Docker Engine and Docker Compose..."
    
    # Add Docker's official GPG key:
    apt-get update
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    log_success "Docker and Docker Compose installed successfully!"
}

manage_containers() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ 🐋 Container Management                                  ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed."
        echo "  1. Install Docker"
        echo "  0. Back"
        read -p "Choice: " c
        [[ "$c" == "1" ]] && install_docker
        return
    fi
    
    echo "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "  1. View All Containers (including stopped)"
    echo "  2. Start/Restart Container"
    echo "  3. Stop Container"
    echo "  4. View Container Logs"
    echo "  5. Deploy One-click Apps (Redis, MongoDB, etc.)"
    echo "  6. 🔀 Create Nginx Proxy for Container"
    echo "  0. Back"
    echo ""
    read -p "Choice: " choice
    
    case $choice in
        1) docker ps -a; pause ;;
        2) 
            read -p "Enter container name: " cname
            docker restart "$cname"
            pause 
            ;;
        3) 
            read -p "Enter container name: " cname
            docker stop "$cname"
            pause 
            ;;
        4) 
            read -p "Enter container name: " cname
            docker logs --tail 50 "$cname"
            pause 
            ;;
        5) deploy_docker_apps ;;
        6) 
            source "$PANDA_DIR/modules/nginx/proxy.sh"
            proxy_bridge_wizard
            ;;
        0) return ;;
    esac
}

deploy_docker_apps() {
    echo ""
    echo "Deploy One-click App:"
    echo "  1. Redis (latest)"
    echo "  2. MongoDB (latest)"
    echo "  3. PostgreSQL (latest)"
    echo "  0. Back"
    echo ""
    read -p "Choice: " appchoice
    
    case $appchoice in
        1) docker run -d --name panda-redis -p 6379:6379 redis:latest; log_success "Redis deployed!"; pause ;;
        2) docker run -d --name panda-mongodb -p 27017:27017 mongo:latest; log_success "MongoDB deployed!"; pause ;;
        3) 
            read -s -p "Set POSTGRES_PASSWORD: " pgpass
            echo ""
            docker run -d --name panda-postgres -e POSTGRES_PASSWORD="$pgpass" -p 5432:5432 postgres:latest
            log_success "PostgreSQL deployed!"
            pause 
            ;;
        *) return ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    manage_containers
fi
