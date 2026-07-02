#!/usr/bin/env bash

# See https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer

# Usage:
# tmux-sessionizer --git
# tmux-sessionizer --root
# tmux-sessionizer --sub-dirs
# tmux-sessionizer --parent-dirs

# Extracting parameters
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -g | --git)
    git_dirs=true
    shift
    ;;
  -r | --root)
    root_dirs=true
    shift
    ;;
  -s | --sub-dirs)
    sub_dirs=true
    shift
    ;;
  -p | --parent-dirs)
    parent_dirs=true
    shift
    ;;
  --tmux)
    tmux_enabled=true
    shift
    ;;
  *)
    shift
    ;;
  esac
done

exclude_dirs=(
  Applications
  Desktop
  Documents
  Downloads
  Library
  Movies
  Music
  Pictures
  Public
  node_modules
)

# Map exclude_dirs to a -E pattern
# See https://www.shellcheck.net/wiki/SC2207
exclude_dirs_patterns=()
IFS=" " read -r -a exclude_dirs_patterns <<<"$(printf -- '-E %s ' "${exclude_dirs[@]}")"

# Call fzf with --tmux if tmux_enabled
fzf_command="fzf --reverse $([[ "$tmux_enabled" ]] && echo '--tmux')"

# Apparently when called from .tmux.conf, $PWD is where the session was created, which is not what we want.
current_working_dir=$([ -n "$tmux_enabled" ] && tmux display-message -p -F "#{pane_current_path}" || pwd)

# In case of git dirs, use fd to find all git dirs
if [[ $git_dirs ]]; then
  selected=$(
    fd -t d -d 3 --no-ignore --hidden "${exclude_dirs_patterns[*]}" .git$ ~/ |
      xargs -I {} dirname {} | $fzf_command
  )
elif [[ $root_dirs ]]; then
  selected=$(
    fd -t d -d 5 --no-ignore --hidden "${exclude_dirs_patterns[*]}" -E .git . --full-path ~/ |
      xargs -I {} dirname {} | $fzf_command
  )
elif [[ $sub_dirs ]]; then
  selected=$(
    fd -t d -d 5 --no-ignore --hidden "${exclude_dirs_patterns[*]}" -E .git . |
      $fzf_command
  )
elif [[ $parent_dirs ]]; then
  splitted_working_dir=()
  IFS="/" read -r -a splitted_working_dir <<<"$current_working_dir"

  selected=$(
    for ((i = ${#splitted_working_dir[@]}; i > 0; i--)); do
      echo "$(IFS="/" ; echo "${splitted_working_dir[*]:0:$i}")" # Copilot generated
    done | $fzf_command
  )
else
  echo '🚨 No option selected. Please use --git, --root or --sub-dirs'
  exit 1
fi

if [[ -z $selected ]]; then
  exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
  tmux new-session -s "$selected_name" -c "$selected"
  exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
  tmux new-session -ds "$selected_name" -c "$selected"
fi

if [[ -z $TMUX ]]; then
  tmux attach -t "$selected_name"
else
  tmux switch-client -t "$selected_name"
fi
