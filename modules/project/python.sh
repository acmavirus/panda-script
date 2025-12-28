#!/bin/bash
#================================================
# Panda Script v2.3 - Python Project Manager
# Auto Virtualenv + Reverse Proxy
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

python_project_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║ 🐍 Python Project Manager                                ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1. 🆕 Create New Python Project"
        echo "  2. 📋 List Python Projects"
        echo "  3. 🚀 Start/Restart Project"
        echo "  4. ⏹️  Stop Project"
        echo "  5. 📝 View Logs"
        echo "  6. 🔄 Clone from GitHub"
        echo "  7. 📦 Install Requirements"
        echo "  8. 🗑️  Delete Project"
        echo "  0. Back"
        echo ""
        read -p "Select option: " choice
        
        case $choice in
            1) create_python_project ;;
            2) list_python_projects ;;
            3) manage_python_project "start" ;;
            4) manage_python_project "stop" ;;
            5) view_python_logs ;;
            6) clone_python_from_github ;;
            7) install_python_requirements ;;
            8) delete_python_project ;;
            0) return ;;
            *) log_error "Invalid option"; pause ;;
        esac
    done
}

create_python_project() {
    local project_name=$(prompt "Enter project name (lowercase)")
    local domain=$(prompt "Enter domain (optional, for reverse proxy)")
    local port=$(prompt "Enter internal port" "8000")
    local framework=$(prompt "Framework (flask/django/fastapi)" "fastapi")
    
    [[ -z "$project_name" ]] && { log_error "Project name required"; pause; return 1; }
    
    # Normalize project name
    project_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    
    local project_dir="/opt/python-apps/$project_name"
    local venv_dir="$project_dir/venv"
    
    if [[ -d "$project_dir" ]]; then
        log_warning "Project directory already exists."
        pause
        return 1
    fi
    
    log_info "Creating Python project: $project_name"
    
    # Ensure Python is installed
    if ! command -v python3 &>/dev/null; then
        log_info "Installing Python3..."
        apt update && apt install -y python3 python3-pip python3-venv
    fi
    
    # Create project directory
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    # Create virtual environment
    log_info "Creating virtual environment..."
    python3 -m venv "$venv_dir"
    source "$venv_dir/bin/activate"
    
    pip install --upgrade pip
    
    # Install framework
    case $framework in
        flask)
            pip install flask gunicorn
            _create_flask_template "$project_dir" "$port"
            ;;
        django)
            pip install django gunicorn
            django-admin startproject config .
            ;;
        fastapi)
            pip install fastapi uvicorn[standard]
            _create_fastapi_template "$project_dir" "$port"
            ;;
    esac
    
    # Freeze requirements
    pip freeze > requirements.txt
    
    deactivate
    
    # Create systemd service
    _create_python_service "$project_name" "$project_dir" "$venv_dir" "$port" "$framework"
    
    # Create Nginx reverse proxy if domain provided
    if [[ -n "$domain" ]]; then
        _create_python_nginx "$domain" "$port"
    fi
    
    # Save project config
    cat > "$project_dir/.panda-project" << EOF
PROJECT_NAME=$project_name
FRAMEWORK=$framework
PORT=$port
DOMAIN=$domain
VENV_DIR=$venv_dir
CREATED=$(date +%Y-%m-%d)
EOF
    
    log_success "Python project '$project_name' created!"
    echo "Directory: $project_dir"
    echo "Port: $port"
    [[ -n "$domain" ]] && echo "Domain: $domain"
    echo ""
    echo "To activate virtualenv: source $venv_dir/bin/activate"
    echo "To start: systemctl start python-$project_name"
    pause
}

_create_flask_template() {
    local project_dir="$1" port="$2"
    
    cat > "$project_dir/app.py" << 'EOF'
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        'message': 'Welcome to Panda Python App!',
        'status': 'running'
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT_PLACEHOLDER)
EOF
    sed -i "s/PORT_PLACEHOLDER/$port/" "$project_dir/app.py"
}

_create_fastapi_template() {
    local project_dir="$1" port="$2"
    
    cat > "$project_dir/main.py" << 'EOF'
from fastapi import FastAPI

app = FastAPI(title="Panda Python App")

@app.get("/")
async def root():
    return {"message": "Welcome to Panda Python App!", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
EOF
}

_create_python_service() {
    local name="$1" project_dir="$2" venv_dir="$3" port="$4" framework="$5"
    
    local exec_start=""
    case $framework in
        flask)
            exec_start="$venv_dir/bin/gunicorn -w 4 -b 127.0.0.1:$port app:app"
            ;;
        django)
            exec_start="$venv_dir/bin/gunicorn -w 4 -b 127.0.0.1:$port config.wsgi:application"
            ;;
        fastapi)
            exec_start="$venv_dir/bin/uvicorn main:app --host 127.0.0.1 --port $port --workers 4"
            ;;
    esac
    
    cat > "/etc/systemd/system/python-$name.service" << EOF
[Unit]
Description=Panda Python App - $name
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$project_dir
ExecStart=$exec_start
Restart=always
RestartSec=5
Environment=PATH=$venv_dir/bin:/usr/bin

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "python-$name"
    log_info "Systemd service 'python-$name' created"
}

_create_python_nginx() {
    local domain="$1" port="$2"
    
    local log_dir="/var/www/$domain/logs"
    mkdir -p "$log_dir"
    
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
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    access_log $log_dir/access.log;
    error_log $log_dir/error.log;
}
EOF

    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    nginx -t && systemctl reload nginx
    log_info "Nginx reverse proxy created for $domain"
}

list_python_projects() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ Python Projects                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    if [[ ! -d "/opt/python-apps" ]] || [[ -z "$(ls -A /opt/python-apps 2>/dev/null)" ]]; then
        log_warning "No Python projects found."
        pause
        return
    fi
    
    printf "%-20s %-12s %-10s %-15s\n" "PROJECT" "FRAMEWORK" "PORT" "STATUS"
    echo "────────────────────────────────────────────────────────────"
    
    for project in /opt/python-apps/*/; do
        [[ ! -d "$project" ]] && continue
        local name=$(basename "$project")
        
        if [[ -f "$project/.panda-project" ]]; then
            source "$project/.panda-project"
            local status=$(systemctl is-active "python-$name" 2>/dev/null || echo "stopped")
            printf "%-20s %-12s %-10s %-15s\n" "$name" "$FRAMEWORK" "$PORT" "$status"
        fi
    done
    echo ""
    pause
}

manage_python_project() {
    local action="$1"
    local project=$(prompt "Enter project name")
    
    [[ -z "$project" ]] && { log_error "Project name required"; pause; return 1; }
    
    if [[ ! -d "/opt/python-apps/$project" ]]; then
        log_error "Project not found: $project"
        pause
        return 1
    fi
    
    case $action in
        start)
            systemctl start "python-$project"
            log_success "Project $project started!"
            ;;
        stop)
            systemctl stop "python-$project"
            log_success "Project $project stopped!"
            ;;
    esac
    pause
}

view_python_logs() {
    local project=$(prompt "Enter project name")
    
    [[ -z "$project" ]] && { log_error "Project name required"; pause; return 1; }
    
    journalctl -u "python-$project" -f --lines=50
}

clone_python_from_github() {
    local repo_url=$(prompt "Enter GitHub repository URL")
    local project_name=$(prompt "Enter project name")
    local domain=$(prompt "Enter domain (optional)")
    local port=$(prompt "Enter port" "8000")
    
    [[ -z "$repo_url" ]] || [[ -z "$project_name" ]] && { log_error "Repo URL and project name required"; pause; return 1; }
    
    project_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    local project_dir="/opt/python-apps/$project_name"
    
    log_info "Cloning repository..."
    git clone "$repo_url" "$project_dir"
    
    cd "$project_dir"
    
    # Create virtualenv
    python3 -m venv venv
    source venv/bin/activate
    
    # Install requirements if exists
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    fi
    
    deactivate
    
    # Detect framework
    local framework="fastapi"
    if grep -q "flask" requirements.txt 2>/dev/null; then
        framework="flask"
    elif grep -q "django" requirements.txt 2>/dev/null; then
        framework="django"
    fi
    
    # Create service
    _create_python_service "$project_name" "$project_dir" "$project_dir/venv" "$port" "$framework"
    
    if [[ -n "$domain" ]]; then
        _create_python_nginx "$domain" "$port"
    fi
    
    # Save config
    cat > "$project_dir/.panda-project" << EOF
PROJECT_NAME=$project_name
FRAMEWORK=$framework
PORT=$port
DOMAIN=$domain
VENV_DIR=$project_dir/venv
GIT_REPO=$repo_url
CREATED=$(date +%Y-%m-%d)
EOF
    
    log_success "Python project cloned and configured!"
    pause
}

install_python_requirements() {
    local project=$(prompt "Enter project name")
    
    [[ -z "$project" ]] && { log_error "Project name required"; pause; return 1; }
    
    local project_dir="/opt/python-apps/$project"
    
    if [[ ! -d "$project_dir" ]]; then
        log_error "Project not found"
        pause
        return 1
    fi
    
    cd "$project_dir"
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    
    log_success "Requirements installed!"
    pause
}

delete_python_project() {
    local project=$(prompt "Enter project name to delete")
    
    [[ -z "$project" ]] && { log_error "Project name required"; pause; return 1; }
    
    read -p "Are you sure you want to delete '$project'? (y/N): " confirm
    [[ "$confirm" != "y" ]] && return
    
    local project_dir="/opt/python-apps/$project"
    
    # Stop and disable service
    systemctl stop "python-$project" 2>/dev/null
    systemctl disable "python-$project" 2>/dev/null
    rm -f "/etc/systemd/system/python-$project.service"
    systemctl daemon-reload
    
    # Remove project directory
    rm -rf "$project_dir"
    
    log_success "Project '$project' deleted!"
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    python_project_menu
fi
