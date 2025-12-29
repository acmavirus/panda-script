#!/bin/bash
#================================================
# Panda Script v2.3 - Deployment Workflow Manager
# GitHub Integration + Auto-Deploy
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

DEPLOY_CONFIG_DIR="/etc/panda/deployments"

deployment_workflow_menu() {
    mkdir -p "$DEPLOY_CONFIG_DIR"
    
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║ 🔄 Deployment Workflow Manager                           ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1. 🆕 Setup New Deployment"
        echo "  2. 📋 List Deployments"
        echo "  3. 🚀 Manual Deploy"
        echo "  4. 🔗 Configure Auto-Deploy (Webhook)"
        echo "  5. 📝 View Deploy Logs"
        echo "  6. ⚙️  Edit Deployment Config"
        echo "  7. 🔄 Pull & Deploy Now"
        echo "  8. 🗑️  Remove Deployment"
        echo "  0. Back"
        echo ""
        read -p "Select: " choice
        case $choice in
            1) setup_deployment ;;
            2) list_deployments ;;
            3) manual_deploy ;;
            4) configure_auto_deploy ;;
            5) view_deploy_logs ;;
            6) edit_deployment ;;
            7) pull_and_deploy ;;
            8) remove_deployment ;;
            0) return ;;
            *) log_error "Invalid"; pause ;;
        esac
    done
}

setup_deployment() {
    local name=$(prompt "Deployment name")
    local repo_url=$(prompt "GitHub/GitLab repository URL")
    local branch=$(prompt "Branch" "main")
    local deploy_path=$(prompt "Deploy path" "/home")
    local project_type=$(prompt "Type (php/nodejs/python/java/static)" "php")
    
    [[ -z "$name" ]] || [[ -z "$repo_url" ]] && { log_error "Name and repo required"; pause; return 1; }
    
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    local full_path="$deploy_path/$name"
    
    mkdir -p "$full_path"
    cd "$full_path"
    
    # Ensure SSH key is accessible for private repos
    export HOME="${HOME:-/root}"
    export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/.ssh/id_rsa -i /root/.ssh/id_ed25519 2>/dev/null"
    
    log_info "Cloning repository..."
    if [[ -d ".git" ]]; then
        git fetch origin && git checkout "$branch" && git pull origin "$branch"
    else
        git clone -b "$branch" "$repo_url" .
    fi
    
    # Generate deploy secret
    local secret=$(generate_password 32)
    
    # Save config
    cat > "$DEPLOY_CONFIG_DIR/$name.conf" << EOF
DEPLOY_NAME=$name
REPO_URL=$repo_url
BRANCH=$branch
DEPLOY_PATH=$full_path
PROJECT_TYPE=$project_type
WEBHOOK_SECRET=$secret
AUTO_DEPLOY=false
PRE_DEPLOY_CMD=
POST_DEPLOY_CMD=
CREATED=$(date +%Y-%m-%d)
EOF

    # Run initial setup
    _run_project_setup "$full_path" "$project_type"
    
    log_success "Deployment '$name' configured!"
    echo ""
    echo "Path: $full_path"
    echo "Type: $project_type"
    echo "Webhook Secret: $secret"
    pause
}

_run_project_setup() {
    local path="$1" type="$2"
    cd "$path"
    
    case $type in
        php)
            [[ -f "composer.json" ]] && composer install --no-dev --optimize-autoloader
            [[ -f "artisan" ]] && php artisan migrate --force && php artisan config:cache
            ;;
        nodejs)
            [[ -f "package.json" ]] && npm install
            grep -q '"build"' package.json 2>/dev/null && npm run build
            ;;
        python)
            if [[ -f "requirements.txt" ]]; then
                python3 -m venv venv
                source venv/bin/activate
                pip install -r requirements.txt
                deactivate
            fi
            ;;
        java)
            [[ -f "pom.xml" ]] && mvn package -DskipTests
            [[ -f "build.gradle" ]] && ./gradlew build -x test
            ;;
        static)
            log_info "Static site - no build needed"
            ;;
    esac
}

list_deployments() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ Configured Deployments                                   ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    if [[ ! -d "$DEPLOY_CONFIG_DIR" ]] || [[ -z "$(ls -A $DEPLOY_CONFIG_DIR/*.conf 2>/dev/null)" ]]; then
        log_warning "No deployments configured"
        pause
        return
    fi
    
    printf "%-20s %-12s %-10s %-20s\n" "NAME" "TYPE" "BRANCH" "AUTO-DEPLOY"
    echo "────────────────────────────────────────────────────────────────"
    
    for conf in "$DEPLOY_CONFIG_DIR"/*.conf; do
        [[ ! -f "$conf" ]] && continue
        source "$conf"
        printf "%-20s %-12s %-10s %-20s\n" "$DEPLOY_NAME" "$PROJECT_TYPE" "$BRANCH" "$AUTO_DEPLOY"
    done
    echo ""
    pause
}

manual_deploy() {
    local name=$(prompt "Deployment name")
    [[ -z "$name" ]] && { log_error "Required"; pause; return 1; }
    
    local conf="$DEPLOY_CONFIG_DIR/$name.conf"
    [[ ! -f "$conf" ]] && { log_error "Deployment not found"; pause; return 1; }
    
    source "$conf"
    _execute_deploy "$DEPLOY_NAME" "$DEPLOY_PATH" "$PROJECT_TYPE" "$BRANCH" "$PRE_DEPLOY_CMD" "$POST_DEPLOY_CMD"
    pause
}

pull_and_deploy() {
    local name=$(prompt "Deployment name")
    [[ -z "$name" ]] && { log_error "Required"; pause; return 1; }
    
    local conf="$DEPLOY_CONFIG_DIR/$name.conf"
    [[ ! -f "$conf" ]] && { log_error "Not found"; pause; return 1; }
    
    source "$conf"
    
    # Ensure SSH key is accessible for private repos
    export HOME="${HOME:-/root}"
    export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/.ssh/id_rsa -i /root/.ssh/id_ed25519 2>/dev/null"
    
    log_info "Pulling latest code..."
    cd "$DEPLOY_PATH"
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
    
    _execute_deploy "$DEPLOY_NAME" "$DEPLOY_PATH" "$PROJECT_TYPE" "$BRANCH" "$PRE_DEPLOY_CMD" "$POST_DEPLOY_CMD"
    pause
}

_execute_deploy() {
    local name="$1" path="$2" type="$3" branch="$4" pre_cmd="$5" post_cmd="$6"
    local log_file="/var/log/panda/deploy-$name.log"
    
    mkdir -p /var/log/panda
    
    log_info "Starting deployment: $name" | tee -a "$log_file"
    echo "$(date): Deployment started" >> "$log_file"
    
    cd "$path"
    
    # Pre-deploy command
    if [[ -n "$pre_cmd" ]]; then
        log_info "Running pre-deploy: $pre_cmd"
        eval "$pre_cmd" 2>&1 | tee -a "$log_file"
    fi
    
    # Project-specific deploy
    _run_project_setup "$path" "$type" 2>&1 | tee -a "$log_file"
    
    # Post-deploy command
    if [[ -n "$post_cmd" ]]; then
        log_info "Running post-deploy: $post_cmd"
        eval "$post_cmd" 2>&1 | tee -a "$log_file"
    fi
    
    # Fix permissions
    source "$PANDA_DIR/modules/system/permissions.sh" 2>/dev/null
    fix_web_permissions "$name" 2>/dev/null
    
    echo "$(date): Deployment completed" >> "$log_file"
    log_success "Deployment completed: $name"
}

configure_auto_deploy() {
    local name=$(prompt "Deployment name")
    [[ -z "$name" ]] && { log_error "Required"; pause; return 1; }
    
    local conf="$DEPLOY_CONFIG_DIR/$name.conf"
    [[ ! -f "$conf" ]] && { log_error "Not found"; pause; return 1; }
    
    source "$conf"
    
    log_info "Creating Webhook endpoint..."
    
    # Create webhook PHP script
    local webhook_dir="/home/webhooks"
    mkdir -p "$webhook_dir"
    
    cat > "$webhook_dir/$name-webhook.php" << 'PHPEOF'
<?php
$secret = 'WEBHOOK_SECRET_PLACEHOLDER';
$deploy_name = 'DEPLOY_NAME_PLACEHOLDER';

$payload = file_get_contents('php://input');
$signature = $_SERVER['HTTP_X_HUB_SIGNATURE_256'] ?? '';

if ($signature) {
    $expected = 'sha256=' . hash_hmac('sha256', $payload, $secret);
    if (!hash_equals($expected, $signature)) {
        http_response_code(401);
        die('Invalid signature');
    }
}

$data = json_decode($payload, true);
$branch = str_replace('refs/heads/', '', $data['ref'] ?? '');

exec("sudo /usr/local/bin/panda deploy $deploy_name 2>&1", $output, $code);

header('Content-Type: application/json');
echo json_encode([
    'status' => $code === 0 ? 'success' : 'failed',
    'output' => implode("\n", $output)
]);
PHPEOF

    sed -i "s/WEBHOOK_SECRET_PLACEHOLDER/$WEBHOOK_SECRET/" "$webhook_dir/$name-webhook.php"
    sed -i "s/DEPLOY_NAME_PLACEHOLDER/$name/" "$webhook_dir/$name-webhook.php"
    
    chown www-data:www-data "$webhook_dir/$name-webhook.php"
    
    # Update config
    sed -i "s/AUTO_DEPLOY=.*/AUTO_DEPLOY=true/" "$conf"
    
    # Add to sudoers
    if ! grep -q "www-data.*panda deploy" /etc/sudoers 2>/dev/null; then
        echo "www-data ALL=(ALL) NOPASSWD: /usr/local/bin/panda deploy *" >> /etc/sudoers
    fi
    
    echo ""
    log_success "Auto-deploy configured!"
    echo ""
    echo "Webhook URL: https://YOUR-DOMAIN/webhooks/$name-webhook.php"
    echo "Secret: $WEBHOOK_SECRET"
    echo ""
    echo "Add this URL to GitHub → Settings → Webhooks"
    pause
}

view_deploy_logs() {
    local name=$(prompt "Deployment name")
    [[ -z "$name" ]] && { log_error "Required"; pause; return 1; }
    
    local log="/var/log/panda/deploy-$name.log"
    [[ ! -f "$log" ]] && { log_warning "No logs found"; pause; return; }
    
    tail -100 "$log"
    pause
}

edit_deployment() {
    local name=$(prompt "Deployment name")
    [[ -z "$name" ]] && { log_error "Required"; pause; return 1; }
    
    local conf="$DEPLOY_CONFIG_DIR/$name.conf"
    [[ ! -f "$conf" ]] && { log_error "Not found"; pause; return 1; }
    
    ${EDITOR:-nano} "$conf"
}

remove_deployment() {
    local name=$(prompt "Deployment name to remove")
    [[ -z "$name" ]] && { log_error "Required"; pause; return 1; }
    
    read -p "Remove deployment config for '$name'? (y/N): " c
    [[ "$c" != "y" ]] && return
    
    rm -f "$DEPLOY_CONFIG_DIR/$name.conf"
    rm -f "/home/webhooks/$name-webhook.php"
    
    log_success "Deployment config removed"
    log_warning "Project files NOT deleted: /home/$name"
    pause
}

# CLI interface for webhook calls
deploy_by_name() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: panda deploy <name>"; return 1; }
    
    local conf="$DEPLOY_CONFIG_DIR/$name.conf"
    [[ ! -f "$conf" ]] && { echo "Deployment not found: $name"; return 1; }
    
    source "$conf"
    
    # Ensure SSH key is accessible for private repos
    export HOME="${HOME:-/root}"
    export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/.ssh/id_rsa -i /root/.ssh/id_ed25519 2>/dev/null"
    
    cd "$DEPLOY_PATH"
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
    
    _execute_deploy "$DEPLOY_NAME" "$DEPLOY_PATH" "$PROJECT_TYPE" "$BRANCH" "$PRE_DEPLOY_CMD" "$POST_DEPLOY_CMD"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && deployment_workflow_menu
