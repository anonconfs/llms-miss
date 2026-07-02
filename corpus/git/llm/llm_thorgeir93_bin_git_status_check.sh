#!/bin/bash
# Script created by ChatGPT.
# Date: Tue Sep 12 09:38:57 PM UTC 2023

function usage() {
    echo "Usage: $0 [path_to_start_directory]"
    echo
    echo "Recursively checks for Git repositories with changes."
    echo "If no directory is provided, current directory is used."
    echo
    echo "Examples:"
    echo "  $0"
    echo "  $0 /path/to/start"
    exit 1
}

# The directory to start the search from
START_DIR="$1"

# If no directory is given, use the current directory
if [ -z "$START_DIR" ]; then
    START_DIR="."
fi

# Recursively search for .git directories
find "$START_DIR" -type d -name .git | while read gitdir; do
    # Get the parent directory of the .git directory
    repo=$(dirname "$gitdir")

    # Go into the repo directory
    pushd "$repo" > /dev/null
    # Check for changes
    if git status --porcelain | grep -q "^ *[MADRCU]"; then
        echo "[ CHANGES ] $repo"
    else
        echo "[ OK ] $repo"
    fi

    # Return to the original directory
    popd > /dev/null
done
