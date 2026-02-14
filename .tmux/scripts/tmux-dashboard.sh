#!/usr/bin/env bash
# tmux-dashboard.sh - Monitor all tmux windows at a glance
# Usage: bound to prefix+D via display-popup in .tmux.conf

set -euo pipefail

SESSION=$(tmux display-message -p '#{session_name}')
REFRESH=2
LINES_PER_WIN=12

draw() {
    clear
    local cols rows col_w
    cols=$(tput cols)
    rows=$(tput lines)
    col_w=$(( (cols - 3) / 2 ))

    # Collect windows
    local -a win_indices=() win_names=() win_actives=()
    while IFS='|' read -r idx name active; do
        win_indices+=("$idx")
        win_names+=("$name")
        win_actives+=("$active")
    done < <(tmux list-windows -t "$SESSION" -F '#{window_index}|#{window_name}|#{window_active}')

    local total=${#win_indices[@]}

    printf "\033[1;34m tmux dashboard — %s — %d windows — [q]uit [r]efresh\033[0m\n\n" \
        "$SESSION" "$total"

    local i=0
    while (( i < total )); do
        local l_idx="${win_indices[$i]}"
        local l_name="${win_names[$i]}"
        local l_active="${win_actives[$i]}"
        local l_marker=" "; [[ "$l_active" == "1" ]] && l_marker="*"

        # Right window (if exists)
        local has_right=0
        local r_idx="" r_name="" r_active="" r_marker=" "
        if (( i + 1 < total )); then
            has_right=1
            r_idx="${win_indices[$((i+1))]}"
            r_name="${win_names[$((i+1))]}"
            r_active="${win_actives[$((i+1))]}"
            [[ "$r_active" == "1" ]] && r_marker="*"
        fi

        # Top border with window names
        local l_hdr
        l_hdr=$(printf "%s %s:%s" "$l_marker" "$l_idx" "$l_name")
        printf "\033[1;36m┌─%s " "$l_hdr"
        local pad=$(( col_w - ${#l_hdr} - 3 ))
        (( pad > 0 )) && printf '%*s' "$pad" '' | tr ' ' '─'

        if (( has_right )); then
            local r_hdr
            r_hdr=$(printf "%s %s:%s" "$r_marker" "$r_idx" "$r_name")
            printf "┬─%s " "$r_hdr"
            pad=$(( col_w - ${#r_hdr} - 3 ))
            (( pad > 0 )) && printf '%*s' "$pad" '' | tr ' ' '─'
            printf "┐\033[0m\n"
        else
            printf "┐\033[0m\n"
        fi

        # Capture pane content (plain text, no ANSI)
        local l_content r_content=""
        l_content=$(tmux capture-pane -t "${SESSION}:${l_idx}" -p -S -${LINES_PER_WIN} 2>/dev/null | tail -${LINES_PER_WIN})
        if (( has_right )); then
            r_content=$(tmux capture-pane -t "${SESSION}:${r_idx}" -p -S -${LINES_PER_WIN} 2>/dev/null | tail -${LINES_PER_WIN})
        fi

        # Print content side by side
        local content_w=$(( col_w - 2 ))
        for (( line=1; line<=LINES_PER_WIN; line++ )); do
            local ll
            ll=$(printf '%s' "$l_content" | sed -n "${line}p" | cut -c1-${content_w})
            printf "│ %-${content_w}s" "$ll"
            if (( has_right )); then
                local rl
                rl=$(printf '%s' "$r_content" | sed -n "${line}p" | cut -c1-${content_w})
                printf "│ %-${content_w}s│" "$rl"
            else
                printf "│"
            fi
            printf "\n"
        done

        # Bottom border
        printf "\033[1;36m└"
        printf '%*s' "$col_w" '' | tr ' ' '─'
        if (( has_right )); then
            printf "┴"
            printf '%*s' "$col_w" '' | tr ' ' '─'
        fi
        printf "┘\033[0m\n"

        i=$(( i + 2 ))
    done
}

# Main loop
trap 'tput cnorm; exit 0' EXIT INT TERM
tput civis  # hide cursor

while true; do
    draw
    if read -rsn1 -t "$REFRESH" key 2>/dev/null; then
        case "$key" in
            q|Q) break ;;
            r|R) continue ;;
        esac
    fi
done
