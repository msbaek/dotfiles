#!/usr/bin/env bash
# tmux-dashboard.sh - Monitor all tmux windows at a glance
# Usage: bound to prefix+D via display-popup in .tmux.conf
# Keys: j/k scroll, gg top, G bottom, r refresh, q quit

set -euo pipefail

SESSION=$(tmux display-message -p '#{session_name}')
REFRESH=5
SCROLL=0

draw() {
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
    local total_rows=$(( (total + 1) / 2 ))

    # Adaptive lines per window: fit as many rows as possible
    local header_lines=2
    local border_lines=2  # top + bottom border per row
    local avail=$(( rows - header_lines ))
    local lpw=$(( (avail / total_rows) - border_lines ))
    (( lpw < 3 )) && lpw=3
    (( lpw > 10 )) && lpw=10

    # Calculate visible rows
    local row_height=$(( lpw + border_lines ))
    local max_visible=$(( avail / row_height ))
    (( max_visible < 1 )) && max_visible=1

    # Clamp scroll
    local max_scroll=$(( total_rows - max_visible ))
    (( max_scroll < 0 )) && max_scroll=0
    (( SCROLL > max_scroll )) && SCROLL=$max_scroll
    (( SCROLL < 0 )) && SCROLL=0

    # Clear and draw
    printf "\033[H\033[2J"

    local end_row=$(( SCROLL + max_visible ))
    (( end_row > total_rows )) && end_row=$total_rows
    local scroll_info=""
    if (( max_scroll > 0 )); then
        scroll_info=$(printf " [%d-%d/%d]" "$((SCROLL+1))" "$end_row" "$total_rows")
    fi
    printf "\033[1;34m %s — %d wins%s — j/k:scroll r:refresh q:quit\033[0m\n\n" \
        "$SESSION" "$total" "$scroll_info"

    # Draw only visible rows
    local start_idx=$(( SCROLL * 2 ))
    local end_idx=$(( (SCROLL + max_visible) * 2 ))
    (( end_idx > total )) && end_idx=$total

    local i=$start_idx
    while (( i < end_idx )); do
        local l_idx="${win_indices[$i]}"
        local l_name="${win_names[$i]}"
        local l_active="${win_actives[$i]}"
        local l_marker=" "; [[ "$l_active" == "1" ]] && l_marker="*"

        # Right window (if exists)
        local has_right=0
        local r_idx="" r_name="" r_active="" r_marker=" "
        if (( i + 1 < total )) && (( i + 1 < end_idx )); then
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

        # Capture pane content (last N lines, plain text)
        local l_content r_content=""
        l_content=$(tmux capture-pane -t "${SESSION}:${l_idx}" -p -S -${lpw} 2>/dev/null | tail -${lpw})
        if (( has_right )); then
            r_content=$(tmux capture-pane -t "${SESSION}:${r_idx}" -p -S -${lpw} 2>/dev/null | tail -${lpw})
        fi

        # Print content side by side
        local content_w=$(( col_w - 2 ))
        for (( line=1; line<=lpw; line++ )); do
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

# Main loop - event driven with vim navigation
trap 'tput cnorm; exit 0' EXIT INT TERM
tput civis

draw
while true; do
    if read -rsn1 -t "$REFRESH" key 2>/dev/null; then
        case "$key" in
            q|Q) break ;;
            r|R) draw ;;
            j|J) (( SCROLL++ )); draw ;;
            k|K) (( SCROLL > 0 )) && (( SCROLL-- )); draw ;;
            G) SCROLL=999999; draw ;;
            g)
                if read -rsn1 -t 0.3 key2 2>/dev/null && [[ "$key2" == "g" ]]; then
                    SCROLL=0; draw
                fi
                ;;
        esac
    else
        draw  # auto-refresh on timeout
    fi
done
