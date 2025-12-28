#!/bin/bash
#================================================
# Panda Script v2.3 - Java Project Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

java_project_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════╗"
        echo "║ ☕ Java Project Manager                  ║"
        echo "╚══════════════════════════════════════════╝"
        echo ""
        echo "  1. 🆕 Create Spring Boot Project"
        echo "  2. 📋 List Java Projects"
        echo "  3. 🚀 Start/Restart Project"
        echo "  4. ⏹️  Stop Project"
        echo "  5. 📝 View Logs"
        echo "  6. 🔄 Clone from GitHub"
        echo "  7. 🔨 Build Project (Maven/Gradle)"
        echo "  8. 🗑️  Delete Project"
        echo "  9. ☕ Install/Switch Java Version"
        echo "  0. Back"
        echo ""
        read -p "Select: " choice
        case $choice in
            1) create_java_project ;;
            2) list_java_projects ;;
            3) manage_java_project "start" ;;
            4) manage_java_project "stop" ;;
            5) view_java_logs ;;
            6) clone_java_from_github ;;
            7) build_java_project ;;
            8) delete_java_project ;;
            9) manage_java_version ;;
            0) return ;;
            *) log_error "Invalid"; pause ;;
        esac
    done
}

ensure_java_installed() {
    if ! command -v java &>/dev/null; then
        log_info "Installing Java 17 (OpenJDK)..."
        apt update && apt install -y openjdk-17-jdk
    fi
    if ! command -v mvn &>/dev/null; then
        apt install -y maven
    fi
}

create_java_project() {
    ensure_java_installed
    local project_name=$(prompt "Enter project name")
    local domain=$(prompt "Enter domain (optional)")
    local port=$(prompt "Enter port" "8080")
    local group_id=$(prompt "Group ID" "com.example")
    
    [[ -z "$project_name" ]] && { log_error "Required"; pause; return 1; }
    project_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local project_dir="/opt/java-apps/$project_name"
    
    [[ -d "$project_dir" ]] && { log_warning "Exists!"; pause; return 1; }
    mkdir -p "$project_dir" && cd "$project_dir"
    
    log_info "Generating Spring Boot project..."
    curl -s "https://start.spring.io/starter.zip?type=maven-project&language=java&bootVersion=3.2.1&baseDir=.&groupId=$group_id&artifactId=$project_name&name=$project_name&packageName=$group_id.$project_name&dependencies=web,actuator" -o starter.zip
    unzip -q starter.zip && rm starter.zip
    
    # Set port
    echo "server.port=$port" >> src/main/resources/application.properties
    echo "management.endpoints.web.exposure.include=health,info" >> src/main/resources/application.properties
    
    # Build
    mvn package -DskipTests
    
    # Create systemd service
    _create_java_service "$project_name" "$project_dir" "$port"
    
    [[ -n "$domain" ]] && _create_java_nginx "$domain" "$port"
    
    cat > .panda-project << EOF
PROJECT_NAME=$project_name
TYPE=spring-boot
PORT=$port
DOMAIN=$domain
CREATED=$(date +%Y-%m-%d)
EOF
    
    log_success "Created $project_name!"
    pause
}

_create_java_service() {
    local name="$1" dir="$2" port="$3"
    local jar_file=$(find "$dir/target" -name "*.jar" | head -1)
    
    cat > "/etc/systemd/system/java-$name.service" << EOF
[Unit]
Description=Java App - $name
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$dir
ExecStart=/usr/bin/java -jar $jar_file --server.port=$port
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable "java-$name"
}

_create_java_nginx() {
    local domain="$1" port="$2"
    mkdir -p "/home/$domain/logs"
    cat > "/etc/nginx/sites-available/$domain" << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    access_log /home/$domain/logs/access.log;
    error_log /home/$domain/logs/error.log;
}
EOF
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    nginx -t && systemctl reload nginx
}

list_java_projects() {
    echo ""
    printf "%-20s %-10s %-15s\n" "PROJECT" "PORT" "STATUS"
    echo "────────────────────────────────────────────"
    for p in /opt/java-apps/*/; do
        [[ ! -d "$p" ]] && continue
        local n=$(basename "$p")
        [[ -f "$p/.panda-project" ]] && source "$p/.panda-project"
        local s=$(systemctl is-active "java-$n" 2>/dev/null || echo "stopped")
        printf "%-20s %-10s %-15s\n" "$n" "${PORT:-8080}" "$s"
    done
    echo "" && pause
}

manage_java_project() {
    local action="$1" project=$(prompt "Project name")
    [[ -z "$project" ]] && { log_error "Required"; pause; return 1; }
    systemctl $action "java-$project"
    log_success "$action completed!"
    pause
}

view_java_logs() {
    local project=$(prompt "Project name")
    [[ -z "$project" ]] && { log_error "Required"; pause; return 1; }
    journalctl -u "java-$project" -f --lines=50
}

clone_java_from_github() {
    ensure_java_installed
    local repo=$(prompt "GitHub URL") name=$(prompt "Project name") port=$(prompt "Port" "8080")
    [[ -z "$repo" ]] || [[ -z "$name" ]] && { log_error "Required"; pause; return 1; }
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local dir="/opt/java-apps/$name"
    git clone "$repo" "$dir" && cd "$dir"
    
    if [[ -f "pom.xml" ]]; then
        mvn package -DskipTests
    elif [[ -f "build.gradle" ]]; then
        ./gradlew build -x test
    fi
    
    _create_java_service "$name" "$dir" "$port"
    log_success "Cloned and built!"
    pause
}

build_java_project() {
    local project=$(prompt "Project name")
    [[ -z "$project" ]] && { log_error "Required"; pause; return 1; }
    cd "/opt/java-apps/$project"
    [[ -f "pom.xml" ]] && mvn package -DskipTests
    [[ -f "build.gradle" ]] && ./gradlew build -x test
    log_success "Built!"
    pause
}

delete_java_project() {
    local project=$(prompt "Project to delete")
    [[ -z "$project" ]] && { log_error "Required"; pause; return 1; }
    read -p "Delete $project? (y/N): " c
    [[ "$c" != "y" ]] && return
    systemctl stop "java-$project" 2>/dev/null
    systemctl disable "java-$project" 2>/dev/null
    rm -f "/etc/systemd/system/java-$project.service"
    systemctl daemon-reload
    rm -rf "/opt/java-apps/$project"
    log_success "Deleted!"
    pause
}

manage_java_version() {
    echo ""
    echo "Installed Java versions:"
    update-alternatives --list java
    echo ""
    echo "1. Install Java 8"
    echo "2. Install Java 11"
    echo "3. Install Java 17"
    echo "4. Install Java 21"
    echo "5. Switch Java version"
    echo "0. Back"
    read -p "Select: " c
    case $c in
        1) apt install -y openjdk-8-jdk ;;
        2) apt install -y openjdk-11-jdk ;;
        3) apt install -y openjdk-17-jdk ;;
        4) apt install -y openjdk-21-jdk ;;
        5) update-alternatives --config java ;;
        0) return ;;
    esac
    pause
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && java_project_menu
