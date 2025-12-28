#!/bin/bash
#================================================
# Panda Script v2.2 - CI/CD Deployment Tool
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

deploy_site() {
    local domain="$1"
    
    [[ -z "$domain" ]] && { log_error "Domain required"; return 1; }
    
    local site_root="/home/$domain"
    local public_root="$site_root/public"
    
    if [[ ! -d "$site_root" ]]; then
        log_error "Site root $site_root not found."
        return 1
    fi
    
    log_info "Starting deployment for $domain..."
    
    cd "$site_root" || return 1
    
    # 1. Git Pull (if .git exists)
    if [[ -d ".git" ]]; then
        log_info "Found Git repository. Pulling latest code..."
        git pull origin main || git pull origin master
    else
        log_warning "No .git directory found. Skipping git pull."
    fi
    
    # 2. Framework Detection & Build Steps
    
    # PHP / Composer
    if [[ -f "composer.json" ]]; then
        log_info "Composer detected. Running install..."
        composer install --no-dev --optimize-autoloader
    fi
    
    # Node / NPM
    if [[ -f "package.json" ]]; then
        log_info "Node.js project detected. Running npm install & build..."
        npm install
        if grep -q "build" package.json; then
            npm run build
        fi
    fi
    
    # Laravel specific
    if [[ -f "artisan" ]]; then
        log_info "Laravel detected. Optimizing..."
        php artisan migrate --force
        php artisan config:cache
        php artisan route:cache
        php artisan view:cache
    fi
    
    # 3. Permissions Alignment
    log_info "Aligning permissions..."
    source "$PANDA_DIR/modules/system/permissions.sh"
    fix_web_permissions "$domain"
    
    log_success "Deployment for $domain completed successfully!"
}

setup_git_repo() {
    local domain="$1"
    local repo_url="$2"
    
    [[ -z "$domain" ]] || [[ -z "$repo_url" ]] && { log_error "Domain and Repo URL required"; return 1; }
    
    local site_root="/home/$domain"
    mkdir -p "$site_root"
    cd "$site_root"
    
    log_info "Initializing Git and cloning repository..."
    if [[ -d ".git" ]]; then
        log_warning "Git already initialized in $site_root"
    else
        git clone "$repo_url" .
    fi
    
    log_success "Git repository linked to $domain"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    deploy_site "$1"
fi
