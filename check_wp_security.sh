#!/bin/bash
for d in /home/*/; do
    if [ -f "${d}wp-config.php" ]; then
        echo "=========================================="
        echo "SITE: $d"
        
        # 1. Version Check
        version=$(grep "wp_version =" "${d}wp-includes/version.php" | cut -d"'" -f2)
        echo "[i] WordPress Version: $version"

        # 2. Critical Files & Backups
        for f in .git .env wp-config.php.bak wp-config.php.save wp-config.old .wp-config.php.swp; do
            if [ -e "${d}$f" ]; then
                echo "[!] CRITICAL: $f found!"
            fi
        done
        
        # 3. Security Risks
        if [ -f "${d}wp-content/debug.log" ]; then
            echo "[!] WARNING: Debug log exposed at wp-content/debug.log"
        fi
        
        # 4. Permissions
        perms=$(stat -c "%a" "${d}wp-config.php")
        owner=$(stat -c "%U:%G" "${d}wp-config.php")
        echo "[i] wp-config.php Perms: $perms (Owner: $owner)"
        
        # 5. PHP in Uploads
        shells=$(find "${d}wp-content/uploads" -name "*.php" 2>/dev/null | wc -l)
        if [ "$shells" -gt 0 ]; then
            echo "[!] CRITICAL: $shells PHP files found in uploads!"
        fi
    fi
done
