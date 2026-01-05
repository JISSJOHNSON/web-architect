#!/bin/bash

# --- Vue Engine Utilities ---
# Most logic has been consolidated into core/ui.sh and core/utils.sh

# Engine-specific cleanup routine
cleanup() {
  local exit_code=$?
  # Clean up core-defined spinner if running
  if [[ -n "${SPINNER_PID:-}" ]]; then 
    kill "$SPINNER_PID" 2>/dev/null || true
    wait "$SPINNER_PID" 2>/dev/null || true
  fi
  if [[ -t 1 ]]; then tput cnorm; fi 
  
  if [ $exit_code -ne 0 ]; then
    echo -e "\n  ${RED}${ICON_CROSS:-✖}${RESET} ${BOLD}Architect failed.${RESET} Exit code: $exit_code"
  fi
  
  if [[ -t 0 && $exit_code -ne 0 ]]; then
      echo -e "\n${BOLD}Press any key to exit...${RESET}"
      read -n 1 -s -r
  fi
}

# Bind the cleanup to the EXIT signal
trap cleanup EXIT
