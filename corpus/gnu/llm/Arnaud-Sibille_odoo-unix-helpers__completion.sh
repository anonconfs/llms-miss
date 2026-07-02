# written by chatgpt, have no clue how it works

_db_name_completion() {
    local cur
    cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(psql -c "SELECT datname FROM pg_database WHERE datname LIKE '$cur%';" -qt) )
}

_db_name_then_file_completion() {
    local cur prev words cword
    _init_completion || return

    case "$cword" in
        1)  # Completing the first argument
            COMPREPLY=( $(psql -c "SELECT datname FROM pg_database WHERE datname LIKE '$cur%';" -qt) )
            ;;
        2)  # Completing the second argument
            COMPREPLY=( $(compgen -f -- "$cur") )  # Complete file and directory names
            ;;
        *)
            # Default completion behavior
            ;;
    esac
}

complete -F _db_name_completion drop-odoo-dbs
complete -F _db_name_completion duplicate-odoo-db
complete -F _db_name_completion migrate-odoo-db
complete -F _db_name_completion launch-odoo-db

complete -F _db_name_then_file_completion execute-odoo-script
