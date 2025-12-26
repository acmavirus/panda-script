#!/bin/bash
#================================================
# Panda Script v2.0 - Cloudflare Manager
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

cf_purge_cache() {
    local zone_id=$(prompt "Enter Cloudflare Zone ID")
    local api_key=$(prompt "Enter Cloudflare API Token")
    
    [[ -z "$zone_id" ]] || [[ -z "$api_key" ]] && { log_error "Zone ID and API Token required"; return 1; }
    
    log_info "Purging Cloudflare cache..."
    
    curl -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/purge_cache" \
         -H "Authorization: Bearer $api_key" \
         -H "Content-Type: application/json" \
         --data '{"purge_everything":true}'
         
    log_success "Cache purge request sent."
    pause
}

# Future: Add DNS record management
