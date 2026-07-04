#!/usr/bin/env bash
# Extract the ground-truth option set for every analysed program by parsing its
# --help, across three studies: GNU CLI tools, CI tools (docker, npm, pip), and
# git subcommands. Writes one option per line to groundtruth/{gnu,ci,git}/<unit>.txt
# plus summary.csv (study,tool,short_options,long_options,total). Requires the
# tool versions pinned in data/groundtruth/versions.txt.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
GROUNDTRUTH_DIR="$BASE_DIR/groundtruth"

rm -rf "$GROUNDTRUTH_DIR"
mkdir -p "$GROUNDTRUTH_DIR"/{gnu,ci,git}

SUMMARY="$GROUNDTRUTH_DIR/summary.csv"
echo "study,tool,short_options,long_options,total" > "$SUMMARY"

# Suppress ANSI escape sequences (hyperlinks, bold) from --help output.
# GNU coreutils 9.10+ emits OSC 8 hyperlinks and SGR bold that break regex parsing.
export TERM=dumb

log() { echo "[$(date +%H:%M:%S)] $*"; }

# =============================================================================
# extract_options <help_text>
#   Prints one option per line. Short options: -X, Long options: --word
# =============================================================================
extract_options() {
    local text="$1"
    {
        # Short options: dash + single alphanumeric, not preceded by word char
        echo "$text" | grep -oP '(?<![a-zA-Z0-9])-[a-zA-Z0-9](?![a-zA-Z0-9])' || true
        # Long options: double-dash + word (at least 2 chars after --)
        echo "$text" | grep -oP -- '--[a-z][a-z0-9-]+' || true
    } | sort -u
}

# =============================================================================
# extract_options_xstyle <help_text>
#   Like extract_options but also captures X-style single-dash multi-character
#   options (e.g. find's -name, -maxdepth; stty's -icanon, -ixon), which the
#   generic short-option pattern misses. Only used for tools whose help
#   documents such options (find, stty); applying it generally would pick up
#   example clusters like "tar -xf" as phantom options.
# =============================================================================
extract_options_xstyle() {
    local text="$1"
    {
        extract_options "$text"
        echo "$text" | grep -oP '(?<![a-zA-Z0-9_-])-[a-zA-Z][a-zA-Z0-9_-]+(?![a-zA-Z0-9_-])' | grep -v '^--' || true
    } | sort -u
}

# =============================================================================
# extract_options_git <help_text>
#   Like extract_options but handles git's --[no-]xxx format.
#   Emits both --xxx and --no-xxx for each --[no-]xxx found.
# =============================================================================
extract_options_git() {
    local text="$1"
    {
        # Short options (same as generic)
        echo "$text" | grep -oP '(?<![a-zA-Z0-9])-[a-zA-Z0-9](?![a-zA-Z0-9])' || true
        # Expand --[no-]xxx into --xxx and --no-xxx
        echo "$text" | grep -oP -- '--\[no-\][a-z][a-z0-9-]+' | sed 's/--\[no-\]/--/' || true
        echo "$text" | grep -oP -- '--\[no-\][a-z][a-z0-9-]+' | sed 's/--\[no-\]/--no-/' || true
        # Plain long options (without [no-] bracket)
        echo "$text" | grep -oP -- '--[a-z][a-z0-9-]+' || true
    } | sort -u
}

# =============================================================================
# write_and_record <study> <tool_name> <output_file>
#   Counts short/long options in the file, appends to summary.csv
# =============================================================================
write_and_record() {
    local study="$1" tool="$2" file="$3"

    if [[ ! -s "$file" ]]; then
        rm -f "$file"
        return
    fi

    local short_count long_count total
    short_count=$(grep -c '^-[^-]' "$file") || short_count=0
    long_count=$(grep -c '^--' "$file") || long_count=0
    total=$(( short_count + long_count ))
    echo "${study},${tool},${short_count},${long_count},${total}" >> "$SUMMARY"
}

# =============================================================================
# STUDY 1: GNU coreutils and common CLI tools
# =============================================================================
log "=== Study 1: GNU coreutils ==="

GNU_TOOLS=(
    arch awk b2sum base32 base64 basename basenc cat chcon chgrp chmod chown
    chroot cksum cmp comm cp csplit cut date dd df diff diff3 dir dircolors
    dirname du echo egrep env expand expr factor false fgrep find fmt fold
    gawk grep groups gunzip gzip head hostid id install join link ln logname
    ls md5sum mkdir mkfifo mknod mktemp mv nice nl nohup nproc numfmt od
    paste pathchk pinky pr printenv printf ptx pwd readlink realpath rm rmdir
    runcon sdiff sed seq sha1sum sha224sum sha256sum sha384sum sha512sum shred
    shuf sleep sort split stat stdbuf stty sum sync tac tail tar tee test
    timeout touch tr true truncate tsort tty uname unexpand uniq unlink unxz
    users vdir wc who whoami xargs xz xzcat yes zcat
)

gnu_count=0
for tool in "${GNU_TOOLS[@]}"; do
    outfile="$GROUNDTRUTH_DIR/gnu/${tool}.txt"

    # Skip if command not found
    if ! command -v "$tool" &>/dev/null; then
        log "  SKIP (not installed): $tool"
        continue
    fi

    # Get help text (some write to stderr, some to stdout)
    help_text=$("$tool" --help 2>&1) || help_text=""

    # Some tools (test, false, true) have minimal/no --help
    if [[ -z "$help_text" ]]; then
        continue
    fi

    # find and stty document X-style single-dash multi-char options
    case "$tool" in
        find|stty) extract_options_xstyle "$help_text" > "$outfile" ;;
        *)         extract_options "$help_text" > "$outfile" ;;
    esac
    write_and_record "gnu" "$tool" "$outfile"

    if [[ -s "$outfile" ]]; then
        gnu_count=$((gnu_count + 1))
    fi
done

log "  Extracted options for $gnu_count GNU tools"

# =============================================================================
# STUDY 2: CI pipeline tools (docker, npm, pip) — ALL subcommands
# =============================================================================
log "=== Study 2: CI pipeline tools ==="

ci_count=0

# --- Docker direct commands (all from docker --help) ---
DOCKER_CMDS=(
    attach build commit cp create diff events exec export history
    images import info inspect kill load login logout logs pause
    port ps pull push rename restart rm rmi run save search start
    stats stop tag top unpause update version wait
)

for subcmd in "${DOCKER_CMDS[@]}"; do
    outfile="$GROUNDTRUTH_DIR/ci/docker_${subcmd}.txt"
    help_text=$(docker "$subcmd" --help 2>&1) || help_text=""
    extract_options "$help_text" > "$outfile"
    write_and_record "ci" "docker_${subcmd}" "$outfile"
    if [[ -s "$outfile" ]]; then ci_count=$((ci_count + 1)); fi
done

# --- Docker Compose subcommands ---
COMPOSE_CMDS=(
    build config cp create down events exec images kill logs ls
    pause port ps pull push restart rm run start stop top unpause
    up version wait watch
)

for subcmd in "${COMPOSE_CMDS[@]}"; do
    outfile="$GROUNDTRUTH_DIR/ci/docker-compose_${subcmd}.txt"
    help_text=$(docker compose "$subcmd" --help 2>&1) || help_text=""
    extract_options "$help_text" > "$outfile"
    write_and_record "ci" "docker-compose_${subcmd}" "$outfile"
    if [[ -s "$outfile" ]]; then ci_count=$((ci_count + 1)); fi
done

# --- npm — ALL subcommands ---
NPM_CMDS=(
    access adduser audit bugs cache ci completion config dedupe
    deprecate diff dist-tag docs doctor edit exec explain explore
    find-dupes fund get help init install install-ci-test
    install-test link ll login logout ls org outdated owner pack
    ping pkg prefix profile prune publish query rebuild repo
    restart root run-script sbom search set shrinkwrap star stars
    start stop team test token uninstall unpublish unstar update
    version view whoami
)

for subcmd in "${NPM_CMDS[@]}"; do
    outfile="$GROUNDTRUTH_DIR/ci/npm_${subcmd}.txt"
    help_text=$(npm "$subcmd" --help 2>&1) || help_text=""
    extract_options "$help_text" > "$outfile"
    write_and_record "ci" "npm_${subcmd}" "$outfile"
    if [[ -s "$outfile" ]]; then ci_count=$((ci_count + 1)); fi
done

# --- pip — ALL subcommands ---
PIP_CMDS=(
    cache check completion config debug download freeze hash
    index inspect install list show uninstall wheel
)

for subcmd in "${PIP_CMDS[@]}"; do
    outfile="$GROUNDTRUTH_DIR/ci/pip_${subcmd}.txt"
    help_text=$(pip3 "$subcmd" --help 2>&1) || help_text=""
    extract_options "$help_text" > "$outfile"
    write_and_record "ci" "pip_${subcmd}" "$outfile"
    if [[ -s "$outfile" ]]; then ci_count=$((ci_count + 1)); fi
done

log "  Extracted options for $ci_count CI tools"

# =============================================================================
# STUDY 3: Git subcommands
# =============================================================================
log "=== Study 3: Git subcommands ==="

GIT_SUBCMDS=(
    add am apply archive bisect blame branch checkout cherry-pick clean
    clone commit config describe diff fetch format-patch gc grep init
    log ls-files ls-remote merge mv notes pull push range-diff rebase
    reflog remote reset restore revert rev-parse rm shortlog show
    sparse-checkout stash status submodule switch tag worktree
)

git_count=0
for subcmd in "${GIT_SUBCMDS[@]}"; do
    outfile="$GROUNDTRUTH_DIR/git/${subcmd}.txt"

    # Use only -h (short structured help, no man page noise)
    # git -h exits 129 (usage) — that's fine, we still want the output
    help_text=$(git "$subcmd" -h 2>&1 || true)

    extract_options_git "$help_text" > "$outfile"
    write_and_record "git" "$subcmd" "$outfile"

    if [[ -s "$outfile" ]]; then
        git_count=$((git_count + 1))
    fi
done

log "  Extracted options for $git_count git subcommands"

# =============================================================================
# FINAL REPORT
# =============================================================================
log ""
log "=========================================="
log " GROUND TRUTH EXTRACTION COMPLETE"
log "=========================================="
log " Results: $GROUNDTRUTH_DIR/"
log "   GNU tools:    $gnu_count  (in gnu/)"
log "   CI tools:     $ci_count  (in ci/)"
log "   Git subcmds:  $git_count  (in git/)"
log ""
log " Summary file: $SUMMARY"
log ""
log " Counts per study:"

awk -F, 'NR > 1 {
    s[$1] += $5; n[$1]++
}
END {
    for (k in s) printf "   %-6s → %3d tools, %5d total options\n", k, n[k], s[k]
}' "$SUMMARY" | sort

log ""
log " Top 15 by option count:"
sort -t, -k5 -nr "$SUMMARY" | head -15 | \
    awk -F, '{printf "   %-20s %4d opts (%d short + %d long)\n", $2, $5, $3, $4}'
log ""
log " Versions:"
log "   coreutils: $(ls --version | head -1 | grep -oP '[0-9]+\.[0-9]+')"
log "   git:       $(git --version | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"
log "   docker:    $(docker --version | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"
log "   npm:       $(npm --version)"
log "   pip:       $(pip3 --version | grep -oP '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)"

# =============================================================================
# Write a versions manifest for reproducibility
# =============================================================================
VERSIONS="$GROUNDTRUTH_DIR/versions.txt"
{
    echo "# Ground Truth Extraction — Tool Versions"
    echo "# Generated: $(date -Is)"
    echo "# OS: $(cat /etc/os-release 2>/dev/null | grep '^PRETTY_NAME=' | cut -d= -f2 | tr -d '\"')"
    echo "# Kernel: $(uname -r)"
    echo ""
    echo "## GNU coreutils and common CLI"
    echo "coreutils=$(ls --version 2>&1 | head -1 | grep -oP '[0-9]+\.[0-9]+')"
    echo "gawk=$(gawk --version 2>&1 | head -1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    echo "grep=$(grep --version 2>&1 | head -1 | grep -oP '[0-9]+\.[0-9]+')"
    echo "sed=$(sed --version 2>&1 | head -1 | grep -oP '[0-9]+\.[0-9]+')"
    echo "tar=$(tar --version 2>&1 | head -1 | grep -oP '[0-9]+\.[0-9]+')"
    echo "find=$(find --version 2>&1 | head -1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"
    echo "diff=$(diff --version 2>&1 | head -1 | grep -oP '[0-9]+\.[0-9]+')"
    echo "gzip=$(gzip --version 2>&1 | head -1 | grep -oP '[0-9]+\.[0-9]+')"
    echo "xz=$(xz --version 2>&1 | head -1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"
    echo ""
    echo "## CI/CD tools"
    echo "docker=$(docker --version 2>&1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"
    echo "docker-compose=$(docker compose version 2>&1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"
    echo "npm=$(npm --version 2>&1)"
    echo "pip=$(pip3 --version 2>&1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"
    echo "python=$(python3 --version 2>&1 | grep -oP '[0-9]+\.[0-9]+(\.[0-9]+)?')"
    echo ""
    echo "## Git"
    echo "git=$(git --version 2>&1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"
} > "$VERSIONS"

log ""
log " Version manifest: $VERSIONS"
