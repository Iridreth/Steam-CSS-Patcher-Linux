#!/usr/bin/env bash
set -euo pipefail

########################
# Script metadata
########################
SCRIPT_NAME="Steam CSS Patcher (Linux)"
CREATED_DATE="4th Jan 2026"
CREDIT="Credit to xtcrefugee's Powershell script for Winblows: https://github.com/xtcrefugee"

########################
# Color setup (TTY-safe)
########################
if [[ -t 1 ]]; then
    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    CYAN="\033[36m"
    BOLD="\033[1m"
    RESET="\033[0m"
else
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" BOLD="" RESET=""
fi

########################
# Helper functions
########################
info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }

ask_yes_no() {
    while true; do
        read -rp "$(echo -e "${CYAN}$1${RESET} ${GREEN}[y]${RESET}es / ${RED}[n]${RESET}o: ")" yn
        case "$yn" in
            y|Y) return 0 ;;
            n|N) return 1 ;;
            *) warn "Please answer y or n." ;;
        esac
    done
}

########################
# Intro banner
########################
clear
echo -e "${BOLD}${CYAN}$SCRIPT_NAME${RESET}"
echo -e "Created: ${CREATED_DATE}"
echo -e "${CREDIT}"
echo "------------------------------------------------------------"
echo

########################
# Detect Steam installation (native or Flatpak)
########################
CSS_DIR=""

# Check native Steam
if [[ -d "$HOME/.steam/steam/steamui/css" ]]; then
    CSS_DIR="$HOME/.steam/steam/steamui/css"
    info "Detected native Steam installation."
fi

# Check Flatpak Steam installations
FLATPAK_CANDIDATES=()
for dir in "$HOME/.var/app/com.valvesoftware.Steam"/*; do
    [[ -d "$dir/.steam/steam/steamui/css" ]] && FLATPAK_CANDIDATES+=("$dir/.steam/steam/steamui/css")
done

# Pick Flatpak candidate if only one or ask user if multiple
if [[ ${#FLATPAK_CANDIDATES[@]} -eq 1 ]] && [[ -z "$CSS_DIR" ]]; then
    CSS_DIR="${FLATPAK_CANDIDATES[0]}"
    info "Detected Flatpak Steam installation."
elif [[ ${#FLATPAK_CANDIDATES[@]} -gt 1 ]]; then
    echo "Multiple Flatpak Steam CSS directories found:"
    i=1
    for c in "${FLATPAK_CANDIDATES[@]}"; do
        echo "  $i) $c"
        ((i++))
    done
    while true; do
        read -rp "Select which CSS directory to use: " sel
        if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#FLATPAK_CANDIDATES[@]} )); then
            CSS_DIR="${FLATPAK_CANDIDATES[$((sel-1))]}"
            info "Selected: $CSS_DIR"
            break
        fi
        warn "Invalid selection."
    done
fi

# Exit if no Steam CSS directory detected
[[ -z "$CSS_DIR" ]] && { error "Could not find Steam CSS directory (native or Flatpak)."; exit 1; }

########################
# Steam detection
########################
check_steam_running() {
    pgrep -x steam >/dev/null || pgrep -f "com.valvesoftware.Steam" >/dev/null
}

warn "Checking if Steam is running..."
while check_steam_running; do
    warn "Steam is currently running!"
    echo -e "Waiting for Steam to exit... (press ${RED}q${RESET} to quit script immediately)"
    for i in {5..1}; do
        echo -ne "Next check in ${YELLOW}$i${RESET} seconds...   \r"
        if read -rsn1 -t 1 input; then
            [[ "$input" == "q" || "$input" == "Q" ]] && warn "User pressed 'q'. Exiting." && exit 0
        fi
    done
    echo -ne "\r                         \r"
done
success "Steam has exited."
ask_yes_no "Steam has fully closed. Continue?" || { warn "Exiting."; exit 0; }

########################
# Detect active chunk~*.css file
########################
info "Detecting active chunk~*.css file..."
CSS_FILE="$(ls -t "$CSS_DIR"/chunk~*.css 2>/dev/null | head -n 1 || true)"
[[ -z "$CSS_FILE" ]] && { error "No chunk~*.css found in $CSS_DIR."; exit 1; }
CSS_NAME="$(basename "$CSS_FILE")"
BACKUP_BASE="$CSS_FILE.backup"
ORIGINAL_BACKUP="$CSS_DIR/.chunk_original.css"

# Create special original backup if it doesn't exist
if [[ ! -f "$ORIGINAL_BACKUP" ]]; then
    cp "$CSS_FILE" "$ORIGINAL_BACKUP"
    success "Original CSS backup created: $(basename "$ORIGINAL_BACKUP")"
else
    info "Original CSS backup already exists: $(basename "$ORIGINAL_BACKUP")"
fi

########################
# Collect backups
########################
refresh_backups() {
    mapfile -t BACKUPS < <(ls -1 "$BACKUP_BASE"* 2>/dev/null | sort)
}
refresh_backups

########################
# CSS strings
########################
STR_WHATSNEW='._17uEBe5Ri8TMsnfELvs8-N{box-sizing:border-box;padding-top:16px;padding-bottom:0px;padding-inline-start:24px;padding-inline-end:16px;position:relative;height:324px;overflow:hidden;background-image:linear-gradient(to top, #171d25 0%, #2d333c 80%)}'
STR_NOWHATSNEW='._17uEBe5Ri8TMsnfELvs8-N{display:none !important;                                                                                                                                                                                                    }'

STR_ADDSHELF='._3SkuN_ykQuWGF94fclHdhJ{box-sizing:border-box;display:flex;color:#a9a9a9;font-size:14px;font-weight:100;letter-spacing:1px;transition-property:opacity;transition-duration:.21s;transition-timing-function:ease-in-out}'
STR_NOADDSHELF='._3SkuN_ykQuWGF94fclHdhJ{display:none !important;                                                                                                                                                                      }'

STR_LEFTCOLUMN='._9sPoVBFyE_vE87mnZJ5aB{flex-shrink:0;display:flex;flex-direction:row;min-width:256px;width:272px;max-width:min( 50%, 100% - 400px );position:relative}'
STR_NOLEFTCOLUMN='._9sPoVBFyE_vE87mnZJ5aB{flex-shrink:0;display:none;flex-direction:row;min-width:256px;width:272px;max-width:min( 50%, 100% - 400px );position:relative}'

########################
# Backup helpers
########################
create_backup() {
    TARGET="$BACKUP_BASE"
    n=1
    while [[ -e "$TARGET" ]]; do TARGET="$BACKUP_BASE.$n"; ((n++)); done
    cp "$CSS_FILE" "$TARGET"
    success "Backup created: $(basename "$TARGET")"
    refresh_backups
}

list_backups() {
    i=1
    for b in "${BACKUPS[@]}"; do
        date_str="$(stat -c '%y' "$b" | cut -d'.' -f1)"
        echo -e "  ${GREEN}$i${RESET}) $(basename "$b")  ${YELLOW}[$date_str]${RESET}"
        ((i++))
    done
}

########################
# Patch CSS interactively
########################
patch_css() {
    ask_yes_no "Create a backup before patching?" && create_backup
    PATCH_FILE="$CSS_FILE.tmp"
    cp "$CSS_FILE" "$PATCH_FILE"
    info "Starting interactive CSS patching..."

    ask_yes_no "Do you wish to remove the What's New section?" && \
        sed -i "s|$STR_WHATSNEW|$STR_NOWHATSNEW|g" "$PATCH_FILE" && \
        success "What's New removed." || warn "Skipped What's New."

    ask_yes_no "Do you wish to remove the Add Shelf function?" && \
        sed -i "s|$STR_ADDSHELF|$STR_NOADDSHELF|g" "$PATCH_FILE" && \
        success "Add Shelf removed." || warn "Skipped Add Shelf."

    ask_yes_no "Do you wish to remove the Left Column?" && \
        sed -i "s|$STR_LEFTCOLUMN|$STR_NOLEFTCOLUMN|g" "$PATCH_FILE" && \
        success "Left Column removed." || warn "Skipped Left Column."

    if ! cmp -s "$CSS_FILE" "$PATCH_FILE"; then
        mv "$PATCH_FILE" "$CSS_FILE"
        success "CSS patch applied successfully."
    else
        warn "No changes made to CSS."
        rm -f "$PATCH_FILE"
    fi
}

########################
# Reverse CSS interactively
########################
reverse_css_changes() {
    PATCH_FILE="$CSS_FILE.tmp"
    cp "$CSS_FILE" "$PATCH_FILE"
    info "Starting interactive CSS reversal..."

    ask_yes_no "Do you wish to restore the What's New section?" && \
        sed -i "s|$STR_NOWHATSNEW|$STR_WHATSNEW|g" "$PATCH_FILE" && \
        success "What's New restored." || warn "Skipped What's New."

    ask_yes_no "Do you wish to restore the Add Shelf function?" && \
        sed -i "s|$STR_NOADDSHELF|$STR_ADDSHELF|g" "$PATCH_FILE" && \
        success "Add Shelf restored." || warn "Skipped Add Shelf."

    ask_yes_no "Do you wish to restore the Left Column?" && \
        sed -i "s|$STR_NOLEFTCOLUMN|$STR_LEFTCOLUMN|g" "$PATCH_FILE" && \
        success "Left Column restored." || warn "Skipped Left Column."

    if ! cmp -s "$CSS_FILE" "$PATCH_FILE"; then
        mv "$PATCH_FILE" "$CSS_FILE"
        success "CSS reversal applied successfully."
    else
        warn "No changes made to CSS."
        rm -f "$PATCH_FILE"
    fi
}

########################
# Restore from regular backup
########################
restore_backup() {
    if (( ${#BACKUPS[@]} == 0 )); then warn "No backups available."; return; fi
    echo -e "${BOLD}${CYAN}Available backups:${RESET}"
    list_backups
    while true; do
        read -rp "Select backup number to restore (or q to quit): " sel
        [[ "$sel" == "q" ]] && return
        if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#BACKUPS[@]} )); then
            RESTORE_FILE="${BACKUPS[$((sel-1))]}"
            ask_yes_no "Restore $(basename "$RESTORE_FILE") to $CSS_NAME?" && cp -f "$RESTORE_FILE" "$CSS_FILE" && success "Backup restored."
            refresh_backups
            break
        fi
        warn "Invalid selection."
    done
}

########################
# Clean old backups
########################
clean_backups() {
    if (( ${#BACKUPS[@]} == 0 )); then warn "No backups to clean."; return; fi
    echo -e "${BOLD}${CYAN}Existing backups:${RESET}"
    list_backups
    echo "Enter backup numbers to delete (space-separated) or Enter to cancel:"
    read -rp "> " selections
    [[ -z "$selections" ]] && warn "No backups selected. Cancelled." && return
    for sel in $selections; do
        if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#BACKUPS[@]} )); then
            FILE="${BACKUPS[$((sel-1))]}"
            ask_yes_no "Delete $(basename "$FILE")?" && rm -f "$FILE" && success "Deleted $(basename "$FILE")" || warn "Skipped $(basename "$FILE")"
            refresh_backups
        else
            warn "Invalid selection: $sel"
        fi
    done
}

########################
# Restore CSS to native defaults
########################
restore_css_defaults() {
    if [[ ! -f "$ORIGINAL_BACKUP" ]]; then
        warn "Original CSS backup not found!"
        return
    fi
    ask_yes_no "Restore $CSS_NAME to original Steam CSS?" && \
        cp -f "$ORIGINAL_BACKUP" "$CSS_FILE" && \
        success "CSS restored to native defaults."
    refresh_backups
}

########################
# Main menu loop
########################
while true; do
    echo
    echo -e "${BOLD}${CYAN}Choose an action:${RESET}"
    if (( ${#BACKUPS[@]} > 0 )); then
        echo -e "  ${GREEN}1${RESET}) Apply CSS changes"
        echo -e "  ${GREEN}2${RESET}) Reverse CSS changes"
        echo -e "  ${GREEN}3${RESET}) Restore from backup"
        echo -e "  ${GREEN}4${RESET}) Clean old backups"
        echo -e "  ${GREEN}5${RESET}) Restore CSS to native defaults"
        echo -e "  ${RED}6${RESET}) Quit"
    else
        echo -e "  ${GREEN}1${RESET}) Apply CSS changes"
        echo -e "  ${GREEN}2${RESET}) Reverse CSS changes"
        echo -e "  ${GREEN}3${RESET}) Restore CSS to native defaults"
        echo -e "  ${RED}4${RESET}) Quit"
    fi

    read -rp "Enter choice: " choice

    # Check Steam before any modification
    if [[ "$choice" =~ ^[1-5]$ ]]; then
        if check_steam_running; then
            warn "Steam is currently running! Please exit Steam before making changes."
            echo "Waiting for Steam to exit... (press ${RED}q${RESET} to quit script immediately)"
            while check_steam_running; do
                for i in {5..1}; do
                    echo -ne "Next check in ${YELLOW}$i${RESET} seconds...   \r"
                    if read -rsn1 -t 1 input; then
                        [[ "$input" == "q" || "$input" == "Q" ]] && warn "User pressed 'q'. Exiting." && exit 0
                    fi
                done
                echo -ne "\r                         \r"
            done
            success "Steam has exited."
        fi
    fi

    if [[ "$choice" == "1" ]]; then
        patch_css
    elif [[ "$choice" == "2" ]]; then
        reverse_css_changes
    elif [[ "$choice" == "3" && ${#BACKUPS[@]} > 0 ]]; then
        restore_backup
    elif [[ "$choice" == "4" && ${#BACKUPS[@]} > 0 ]]; then
        clean_backups
    elif [[ "$choice" == "5" && ${#BACKUPS[@]} > 0 ]]; then
        restore_css_defaults
    elif [[ "$choice" == "3" && ${#BACKUPS[@]} == 0 ]]; then
        restore_css_defaults
    elif [[ "$choice" == "6" && ${#BACKUPS[@]} > 0 ]] || [[ "$choice" == "4" && ${#BACKUPS[@]} == 0 ]]; then
        warn "Exiting."
        exit 0
    else
        warn "Invalid selection."
    fi
done
