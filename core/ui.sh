#!/bin/bash

# --- Shared UI Library ---

# --- Stylistic Tokens ---
export BOLD='\033[1m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[1;35m'
export WHITE='\033[1;37m'
export YELLOW='\033[1;33m'
export RED='\033[1;31m'
export UNDERLINE='\033[4m'
export RESET='\033[0m'

# Icons
export ICON_CHECK="✓"
export ICON_CROSS="✖"
export ICON_INFO="ℹ"
export ICON_WARN="⚠"

# --- Logging & UI ---
log_header() { echo -e "${BOLD}${MAGENTA}==>${RESET} ${BOLD}${WHITE}$1${RESET}"; }
log_info() { echo -e "  ${BLUE}${ICON_INFO}${RESET}  $1"; }
log_success() { echo -e "  ${GREEN}${ICON_CHECK}${RESET}  $1"; }
log_warn() { echo -e "  ${YELLOW}${ICON_WARN}${RESET}  $1"; }
log_error() { echo -e "  ${RED}${ICON_CROSS}${RESET}  $1"; }
fatal_error() { echo -e "\n  ${RED}${ICON_CROSS}${RESET} ${RED}error${RESET} $1"; exit 1; }

# --- Animations ---
typewriter() {
  local text="$1"
  local delay="${2:-0.02}"
  for ((i=0; i<${#text}; i++)); do
    echo -n "${text:$i:1}"
    sleep "$delay"
  done
  echo ""
}

# --- Spinner ---
SPINNER_PID=""

start_spinner() {
    if [[ ! -t 1 ]]; then
        echo "  $1..."
        return
    fi
    tput civis # hide cursor
    local msg="$1"
    set +m
    {
        local -a marks=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        while true; do
            for mark in "${marks[@]}"; do
                echo -ne "\r  ${CYAN}${mark}${RESET} ${msg}..."
                sleep 0.1
            done
        done
    } 2>/dev/null &
    SPINNER_PID=$!
}

stop_spinner() {
    if [[ -n "${SPINNER_PID:-}" ]]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        SPINNER_PID=""
        echo -ne "\r\033[K" # clear line
    fi
    if [[ -t 1 ]]; then tput cnorm; fi # restore cursor
    if [[ -n "${1:-}" ]]; then
        log_success "$1"
    fi
}

# --- Interactive Menus ---
# select_option: A single-choice interactive menu
# Usage: select_option "Prompt" "Option1" "Option2" ...
# Returns selected index via EXIT CODE (capture with $?)
select_option() {
  local prompt="$1"
  shift
  local options=("$@")
  local selection=0
  
  tput civis >&2 # Hide cursor
  while true; do
    echo -e "  ${BOLD}${BLUE}?${RESET} ${BOLD}${WHITE}${prompt}${RESET}" >&2
    for ((i=0; i<${#options[@]}; i++)); do
      tput el >&2
      if [[ $i -eq $selection ]]; then
        echo -e "  ${GREEN}▶ ${BOLD}${WHITE}${options[$i]}${RESET}" >&2
      else
        echo -e "    ${WHITE}${options[$i]}${RESET}" >&2
      fi
    done
    
    IFS= read -r -s -n 1 key < /dev/tty
    if [[ "$key" == $'\x1b' ]]; then
        read -r -s -n 2 key < /dev/tty
        if [[ "$key" == "[A" ]]; then
            ((selection--)); if [[ $selection -lt 0 ]]; then selection=$((${#options[@]} - 1)); fi
        elif [[ "$key" == "[B" ]]; then
             ((selection++)); if [[ $selection -ge ${#options[@]} ]]; then selection=0; fi
        fi
        tput cuu $((${#options[@]} + 1)) >&2
    elif [[ "$key" == "" ]]; then break
    else tput cuu $((${#options[@]} + 1)) >&2
    fi
  done
  tput cnorm >&2
  return $selection
}

# select_multiple: A multi-choice interactive menu with toggles
# Usage: select_multiple "Prompt" "Option1" "Option2" ...
# Returns newline-separated "true"/"false" strings to STDOUT
select_multiple() {
  local prompt="$1"
  local default_state="${DEFAULT_SELECTION:-false}"
  shift
  local options=("$@")
  local selections=()
  local current=0
  
  # Initialize options with default state
  for ((i=0; i<${#options[@]}; i++)); do selections[$i]="$default_state"; done

  tput civis >&2 # Hide cursor
  while true; do
    echo -e "  ${BOLD}${BLUE}?${RESET} ${BOLD}${WHITE}${prompt}${RESET} ${CYAN}(Space to toggle, Enter to confirm)${RESET}" >&2
    for ((i=0; i<${#options[@]}; i++)); do
      tput el >&2 # Clear line for clean redraw
      local marker=" "
      [[ "${selections[$i]}" == "true" ]] && marker="${GREEN}◉${RESET}" || marker="○"
      
      # Highlight the current hovered item
      if [[ $i -eq current ]]; then
        echo -e "  ${CYAN}▶${RESET} ${marker} ${BOLD}${WHITE}${options[$i]}${RESET}" >&2
      else
        echo -e "    ${marker} ${WHITE}${options[$i]}${RESET}" >&2
      fi
    done

    # Read raw keyboard input
    IFS= read -r -s -n 1 key < /dev/tty
    if [[ "$key" == $'\x1b' ]]; then
      # Handle arrow keys (Escape sequence)
      read -r -s -n 2 key < /dev/tty
      if [[ "$key" == "[A" ]]; then
        ((current--)); if [[ $current -lt 0 ]]; then current=$((${#options[@]} - 1)); fi
      elif [[ "$key" == "[B" ]]; then
        ((current++)); if [[ $current -ge ${#options[@]} ]]; then current=0; fi
      fi
      tput cuu $((${#options[@]} + 1)) >&2 # Move cursor up to redraw menu
    elif [[ "$key" == " " ]]; then
      # Toggle selection state on Spacebar
      [[ "${selections[$current]}" == "true" ]] && selections[$current]="false" || selections[$current]="true"
      tput cuu $((${#options[@]} + 1)) >&2
    elif [[ "$key" == "" ]]; then
      # Accept selection on Enter
      break
    else
      # Re-draw on unknown key
      tput cuu $((${#options[@]} + 1)) >&2
    fi
  done
  tput cnorm >&2 # Show cursor
  
  # Stream selections back to caller via STDOUT (newline separated)
  for ((i=0; i<${#options[@]}; i++)); do
    echo "${selections[$i]}"
  done
}
