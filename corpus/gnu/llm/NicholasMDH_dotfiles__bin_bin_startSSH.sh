#!/bin/bash
# This script was created by chatGPT to replace my previous startSSH script
# This script starts ssh-agent if one isn’t already running,
# and then attempts to add your default SSH keys.

# Check if SSH_AUTH_SOCK is set and is a valid socket
if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
    # Start a new ssh-agent in the background and evaluate its output to set env variables
    eval "$(ssh-agent -s)" >/dev/null
fi

# Try to list keys; if none are added (or agent isn’t accessible), add keys now.
if ! ssh-add -l >/dev/null 2>&1; then
    ssh-add
fi

