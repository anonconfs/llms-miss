#!/usr/bin/env bash
# speedbase.sh — Base conversion speed drill 
# (decimal <--> base-N)
# written by chatgpt4, not denshinobi

set -euo pipefail IFS=$'\n\t' usage() { echo 
    "Usage: $0 <base (2–16)> [--reverse] 
    [--hard]" exit 1
}

# Validate input base
[[ $# -ge 1 ]] || usage base="$1" shift [[ 
"$base" =~ ^[0-9]+$ ]] || usage (( base >= 2 && 
base <= 16 )) || usage

# Flags
reverse_mode=0 hard_mode=0 for arg in "$@"; do 
    case "$arg" in
        --reverse) reverse_mode=1 ;; --hard) 
        hard_mode=1 ;; *) usage ;;
    esac done

# Configuration
digits=(0 1 2 3 4 5 6 7 8 9 A B C D E F) score=0 
total=0 time_limit=5 max_val=$((hard_mode ? 4095 
: 255))
echo "Base-$base Speed Drill" (( reverse_mode )) 
&& echo "Mode: Decimal → Base-$base" || echo 
"Mode: Base-$base → Decimal" (( hard_mode )) && 
echo "Difficulty: HARD (0–4095)" || echo 
"Difficulty: EASY (0–255)" echo "You have 
${time_limit}s per question. Press Ctrl+C to 
quit." echo

# Convert decimal to base-N
to_base_n() { local num=$1 base=$2 out="" local 
    digits=(0 1 2 3 4 5 6 7 8 9 A B C D E F) (( 
    num == 0 )) && { echo 0; return; } while (( 
    num > 0 )); do
        out="${digits[num % base]}$out" (( num 
        /= base ))
    done echo "$out"
}
normalize() { echo "$1" | tr '[:lower:]' 
    '[:upper:]' | tr -d ' '
}

# Game loop
while true; do num=$(( RANDOM % (max_val + 1) )) 
    (( total++ )) if (( reverse_mode )); then
        prompt="Decimal: $num → Base-$base: " 
        correct=$(to_base_n "$num" "$base")
    else base_n=$(to_base_n "$num" "$base") 
        prompt="Base-$base: $base_n → Decimal: " 
        correct="$num"
    fi echo -n "$prompt" read -t "$time_limit" 
    answer || answer="timeout" 
    answer=$(normalize "$answer") if [[ 
    "$answer" == "$(normalize "$correct")" ]]; 
    then
        echo "✔ Correct" (( score++ )) elif [[ 
    "$answer" == "timeout" ]]; then
        echo "✖ Timeout (Answer: $correct)" else 
        echo "✖ Incorrect (Answer: $correct)"
    fi echo "Score: $score / $total" echo
done
