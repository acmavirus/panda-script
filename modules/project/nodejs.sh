#!/bin/bash
#================================================
# Panda Script v2.3 - Node.js Project Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

nodejs_project_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════╗"
        echo "║ 🟢 Node.js Project Manager              ║"
        echo "╚══════════════════════════════════════════╝"
        echo ""
        echo "  1. 🆕 Create New Project"
        echo "  2. 📋 List All Projects"
        echo "  3. 🚀 Start/Restart Project"
        echo "  4. ⏹️  Stop Project"
        echo "  5. 📝 View Logs"
        echo "  6. 🔄 Clone from GitHub"
        echo "  7. 📦 Install Dependencies"
        echo "  8. 🔨 Build Project"
        echo "  9. 🗑️  Delete Project"
        echo "  A. 🔧 PM2 Dashboard"
        echo "  0. Back"
        echo ""
        read -p "Select: " choice
        case $choice in
            1) create_nodejs_project ;;
            2) list_nodejs_projects ;;
            3) manage_nodejs_project "restart" ;;
            4) manage_nodejs_project "stop" ;;
            5) view_nodejs_logs ;;
            6) clone_nodejs_from_github ;;
            7) install_nodejs_deps ;;
            8) build_nodejs_project ;;
            9) delete_nodejs_project ;;
            a|A) pm2_dashboard ;;
            0) return ;;
            *) log_error "Invalid"; pause ;;
        esac
    done
}

ensure_node_installed() {
    if ! command -v node &>/dev/null; then
        log_info "Installing Node.js via NVM..."
        [[ ! -d "$HOME/.nvm" ]] && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts && nvm use --lts
    fi
    ! command -v pm2 &>/dev/null && npm install -g pm2
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

create_nodejs_project() {
    ensure_node_installed
    local project_name=$(prompt "Enter project name")
    local domain=$(prompt "Enter domain (optional)")
    local port=$(prompt "Enter port" "3000")
    [[ -z "$project_name" ]] && { log_error "Name required"; pause; return 1; }
    project_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local project_dir="/opt/nodejs-apps/$project_name"
    [[ -d "$project_dir" ]] && { log_warning "Exists!"; pause; return 1; }
    mkdir -p "$project_dir" && cd "$project_dir"
    npm init -y && npm install express
    cat > app.js << EOF
const express = require('express');
const app = express();
app.get('/', (req, res) => res.json({message: 'Panda Node.js App'}));
app.listen($port, () => console.log('Running on port $port'));
EOF
    npm pkg set scripts.start="node app.js"
    _create_pm2_config "$project_name" "$project_dir" "$port"
    [[ -n "$domain" ]] && _create_nodejs_nginx "$domain" "$port"
    cat > .panda-project << EOF
PROJECT_NAME=$project_name
PORT=$port
DOMAIN=$domain
CREATED=$(date +%Y-%m-%d)
EOF
    log_success "Created $project_name!"
    pause
}

_create_pm2_config() {
    local name="$1" dir="$2" port="$3"
    mkdir -p /var/log/pm2
    cat > "$dir/ecosystem.config.js" << EOF
module.exports = {
  apps: [{
    name: '$name',
    script: 'app.js',
    cwd: '$dir',
    env: { NODE_ENV: 'production', PORT: $port },
    instances: 'max',
    exec_mode: 'cluster'
  }]
};
EOF
}

_create_nodejs_nginx() {
    local domain="$1" port="$2"
    mkdir -p "/var/www/$domain/logs"
    cat > "/etc/nginx/sites-available/$domain" << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    access_log /var/www/$domain/logs/access.log;
    error_log /var/www/$domain/logs/error.log;
}
EOF
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    nginx -t && systemctl reload nginx
}

list_nodejs_projects() {
    ensure_node_installed
    echo "" && pm2 list
    pause
}

manage_nodejs_project() {
    ensure_node_installed
    local action="$1" project=$(prompt "Enter project name")
    [[ -z "$project" ]] && { log_error "Required"; pause; return 1; }
    pm2 $action "$project" && pm2 save
    log_success "$action completed!"
    pause
}

view_nodejs_logs() {
    ensure_node_installed
    local project=$(prompt "Project name (blank=all)")
    [[ -n "$project" ]] && pm2 logs "$project" --lines 50 || pm2 logs --lines 50
}

clone_nodejs_from_github() {
    ensure_node_installed
    local repo=$(prompt "GitHub URL") name=$(prompt "Project name") port=$(prompt "Port" "3000")
    [[ -z "$repo" ]] || [[ -z "$name" ]] && { log_error "Required"; pause; return 1; }
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    git clone "$repo" "/opt/nodejs-apps/$name"
    cd "/opt/nodejs-apps/$name" && npm install
    grep -q '"build"' package.json && npm run build
    _create_pm2_config "$name" "/opt/nodejs-apps/$name" "$port"
    log_success "Cloned!"
    pause
}

install_nodejs_deps() {
    local project=$(prompt "Project name")
    [[ -z "$project" ]] && { log_error "Required"; pause; return 1; }
    cd "/opt/nodejs-apps/$project" && npm install
    log_success "Done!"
    pause
}

build_nodejs_project() {
    local project=$(prompt "Project name")
    [[ -z "$project" ]] && { log_error "Required"; pause; return 1; }
    cd "/opt/nodejs-apps/$project"
    grep -q '"build"' package.json && npm run build || log_warning "No build script"
    pause
}

delete_nodejs_project() {
    ensure_node_installed
    local project=$(prompt "Project to delete")
    [[ -z "$project" ]] && { log_error "Required"; pause; return 1; }
    read -p "Delete $project? (y/N): " c
    [[ "$c" != "y" ]] && return
    pm2 delete "$project" 2>/dev/null; pm2 save
    rm -rf "/opt/nodejs-apps/$project"
    log_success "Deleted!"
    pause
}

pm2_dashboard() {
    ensure_node_installed
    while true; do
        clear && pm2 list
        echo "" && echo "1.Restart 2.Stop 3.Delete 4.Save 5.Monitor 0.Back"
        read -p "Select: " c
        case $c in
            1) pm2 restart all; pause ;;
            2) pm2 stop all; pause ;;
            3) pm2 delete all; pause ;;
            4) pm2 save; pause ;;
            5) pm2 monit ;;
            0) return ;;
        esac
    done
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && nodejs_project_menu
