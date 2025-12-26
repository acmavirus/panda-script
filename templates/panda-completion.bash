# Bash completion for Panda Script
# Save to /etc/bash_completion.d/panda

_panda_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Subcommands
    opts="website database ssl backup php nginx monitoring security performance system docker cloudflare developer doctor deploy debug optimize tunnel"
    
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
    
    # Domain autocompletion for certain subcommands
    case "${prev}" in
        website|ssl|deploy|debug|optimize)
            local domains=$(ls /etc/nginx/sites-available 2>/dev/null)
            COMPREPLY=( $(compgen -W "${domains}" -- ${cur}) )
            return 0
            ;;
    esac
}

complete -F _panda_completions panda
