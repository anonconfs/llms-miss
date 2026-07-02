#!/bin/bash

#Generated with chatgpt


set -euo pipefail

BRANCH="$1"

echo "🔁 Switching to branch: $BRANCH"
git checkout "$BRANCH"

echo "🧹 Deinitializing all submodules..."
git submodule deinit -f --all || true

echo "📄 Reading submodules for branch: $BRANCH"
git submodule sync
git submodule update --init --recursive

# Gather current submodule paths
active_submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

# Find all potential submodule directories (by past use or leftover state)
echo "🔎 Scanning for stale submodule directories..."
possible_submodules=$(find . -type d -maxdepth 2 -not -path "./.git*" -not -path ".")

for dir in $possible_submodules; do
    clean_path="${dir#./}"
    if [[ -d "$clean_path/.git" || -f "$clean_path/.git" ]]; then
        if ! echo "$active_submodules" | grep -qx "$clean_path"; then
            echo "❌ Removing stale submodule: $clean_path"
            git rm --cached -f "$clean_path" 2>/dev/null || true
            rm -rf "$clean_path"
        fi
    fi
done

echo "✅ Remaining submodules updated for $BRANCH"
git submodule update --init --recursive

# Prompt for untracked file cleanup
untracked=$(git ls-files --others --exclude-standard)
if [ -n "$untracked" ]; then
    echo "⚠️  Untracked files/directories detected:"
    echo "$untracked"
    echo ""
    read -p "Delete untracked files with 'git clean -fdx'? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "🧽 Cleaning..."
        git clean -fdx
    else
        echo "❎ Skipping cleanup of untracked files."
    fi
else
    echo "✅ No untracked files to clean."
fi

echo "🎉 Done. Branch '$BRANCH' is now clean and has only its intended submodules."
