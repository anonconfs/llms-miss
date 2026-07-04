#!/usr/bin/env bash
# 02-mine-linux-kernel-scripts.sh
#
# Downloads all shell (.sh) scripts from the latest stable Linux kernel.
# Source: kernel.org (official tarball, no GitHub API needed)
#
# Output : ../corpus/gnu/linux/  (files named as: original_path_underscored.sh)
# Version: ../corpus/gnu/linux/kernel-version.txt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/../corpus/gnu/linux"
VERSION_FILE="$OUT_DIR/kernel-version.txt"
WORK_DIR="/tmp/linux-kernel-mining"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# 1. Determine latest stable kernel version

log "Querying kernel.org for latest stable version..."
VERSION=$(curl -sL https://www.kernel.org/finger_banner \
          | grep -i "^The latest stable version" \
          | grep -oP '\d+\.\d+\.\d+' | head -1)

[[ -z "$VERSION" ]] && { echo "ERROR: could not determine kernel version" >&2; exit 1; }

MAJOR="${VERSION%%.*}"
TARBALL="linux-${VERSION}.tar.xz"
URL="https://cdn.kernel.org/pub/linux/kernel/v${MAJOR}.x/${TARBALL}"

log "Latest stable kernel: $VERSION"

# 2. Download the tarball

mkdir -p "$WORK_DIR"
TARBALL_PATH="$WORK_DIR/$TARBALL"

if [[ -f "$TARBALL_PATH" ]]; then
    log "Tarball already present, skipping download"
else
    log "Downloading $TARBALL (~140 MB from kernel.org)..."
    curl -L --progress-bar "$URL" -o "$TARBALL_PATH"
    log "Download complete"
fi

# 3. Extract only .sh files

EXTRACT_DIR="$WORK_DIR/extracted-$VERSION"

if [[ -d "$EXTRACT_DIR" ]]; then
    log "Already extracted: $EXTRACT_DIR"
else
    log "Extracting *.sh files (this may take a minute)..."
    mkdir -p "$EXTRACT_DIR"
    # Note: -C must come before --wildcards; omit --strip-components to avoid
    # a GNU tar quirk where -C is ignored when both flags are combined.
    tar -xJf "$TARBALL_PATH" -C "$EXTRACT_DIR" --wildcards --no-anchored '*.sh'
    log "Extraction complete"
fi

# 4. Copy to output with flattened names
# Tarball path   linux-7.0.9/Documentation/admin-guide/aoe/autoload.sh
# Output name    Documentation_admin-guide_aoe_autoload.sh

mkdir -p "$OUT_DIR"
count=0

while IFS= read -r f; do
    # Strip the EXTRACT_DIR prefix, then also strip the linux-X.Y.Z/ top dir
    rel="${f#"$EXTRACT_DIR/linux-$VERSION/"}"
    cp "$f" "$OUT_DIR/${rel//\//_}"
    (( count++ )) || true
    (( count % 200 == 0 )) && log "  Copied $count files..."
done < <(find "$EXTRACT_DIR" -name "*.sh" -type f | sort)

log "Saved $count shell scripts → $OUT_DIR/"

# 5. Record kernel version for reproducibility

mkdir -p "$(dirname "$VERSION_FILE")"
{
    echo "version=$VERSION"
    echo "source=kernel.org"
    echo "url=$URL"
    echo "script_count=$count"
    echo "fetched=$(date -Is)"
} > "$VERSION_FILE"

log "Version recorded → $VERSION_FILE"
log "Done."
