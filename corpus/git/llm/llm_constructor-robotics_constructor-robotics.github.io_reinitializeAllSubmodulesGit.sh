#!/bin/bash

set -e
echo "This script was written by AI"
echo "Step 1: Deinitializing all submodules..."
git submodule deinit -f --all

echo "Step 2: Removing submodule paths from index..."
SUBMODULE_PATHS=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

for path in $SUBMODULE_PATHS; do
    echo "Removing $path"
    git rm -f "$path"
    rm -rf "$path"
done

echo "Step 3: Cleaning up .git/modules/..."
rm -rf .git/modules/*

echo "Step 4: Resetting to current branch..."
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
git checkout "$CURRENT_BRANCH" -- .gitmodules
git reset --hard

echo "Step 5: Reinitializing and updating submodules..."
git submodule update --init --recursive --force

echo "✅ Done. All submodules are reset to match the branch '$CURRENT_BRANCH'"
