#!/bin/bash
#================================================
# Panda Script v2.2 - Cloudflare Tunnel Tool
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

install_cloudflared() {
    if ! command -v cloudflared &>/dev/null; then
        log_info "Installing cloudflared tool..."
        curl -L --output /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        dpkg -i /tmp/cloudflared.deb &>/dev/null
        rm /tmp/cloudflared.deb
        log_success "cloudflared installed."
    fi
}

start_tunnel_quick() {
    local port="$1"
    [[ -z "$port" ]] && port="80"
    
    log_info "Starting temporary tunnel for port $port..."
    log_warning "This will provide a public URL for your local service."
    log_info "Press Ctrl+C to stop the tunnel."
    echo ""
    
    cloudflared tunnel --url "http://localhost:$port"
}

tunnel_menu() {
    while true; do
        clear
        print_header "🔀 Cloudflare Tunneling"
        echo "  1. Start Quick Tunnel (Port 80)"
        echo "  2. Start Tunnel on Custom Port"
        echo "  0. Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) install_cloudflared; start_tunnel_quick 80 ;;
            2) 
                local p=$(prompt "Enter port number")
                install_cloudflared; start_tunnel_quick "$p" 
                ;;
            0) return ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tunnel_menu
fi
