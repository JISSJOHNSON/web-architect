#!/bin/bash

# ==============================================================================
#  Web Architect
#  ------------------------------------------------------------------------------
#  A scalable, modular platform for scaffolding modern web applications.
#  Currently supporting: Frontend (Vue.js)
#  Future support: React, Angular, Node.js, Laravel, etc.
# ==============================================================================

# --- Environment Setup ---
set -o errexit   # Exit on error
set -o nounset   # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Establish the platform root directory
cd "$(dirname "$0")"
export ARCHITECT_ROOT="$(pwd)"

# --- Library Imports ---
source "$ARCHITECT_ROOT/core/ui.sh"
source "$ARCHITECT_ROOT/core/utils.sh"
source "$ARCHITECT_ROOT/core/init.sh"
source "$ARCHITECT_ROOT/core/versions.sh"

# --- Global State ---
PROJECT_NAME="${PROJECT_NAME:-}"
PROJECT_DIR="${PROJECT_DIR:-}"
PROJECT_TYPE=""
SELECTED_ENGINE=""
START_TIME=$(get_timestamp)

# ==============================================================================
#  Main Execution Flow
# ==============================================================================

main() {
  print_banner
  
  # 1. Project Configuration
  setup_project_metadata

  # 2. Technology Stack Selection
  select_stack_and_engine
  
  # 3. Load Engine Module
  load_engine_module "$SELECTED_ENGINE"

  # 4. Engine Specific Menu (Includes Build Tool, Features, etc.)
  if [[ "${SILENT_MODE:-false}" != "true" ]]; then
    run_engine_lifecycle "menu"
  fi

  # 5. Select Version Profile
  if [[ "${SILENT_MODE:-false}" != "true" ]]; then
    select_version_profile "$SELECTED_ENGINE"
  fi

  # 6. Execute Pipeline
  setup_project_dir "$PROJECT_DIR" "$PROJECT_NAME"
  
  # Engine specific execution flow
  run_engine_lifecycle "initialize"
  run_engine_lifecycle "install"
  run_engine_lifecycle "structure"
  
  # Engine specific generation (Standardized or Custom)
  # We check for standard generator functions being present
  run_task_if_exists "write_build_config"
  run_task_if_exists "write_tailwind_config"
  run_task_if_exists "write_eslint_config"
  run_task_if_exists "write_code_files"
  
  # Final Scripts update if available
  if command -v update_scripts &> /dev/null; then
    update_scripts
  fi

  init_git
  finalize_git
  
  # Summary
  local duration=$(( $(get_timestamp) - START_TIME ))
  log_header "Scaffolding Completed in ${duration}s!"
  
  echo -e "\n  ${BOLD}${WHITE}Quick Start Steps:${RESET}"
  echo -e "    ${CYAN}1.${RESET} cd $PROJECT_DIR"
  echo -e "    ${CYAN}2.${RESET} npm run dev\n"
}

# --- Core Functions ---

print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
   _    _      _        ___           _     _ _            _   
  | |  | |    | |      / _ \         | |   (_) |          | |  
  | |  | | ___| |__   / /_\ \_ __ ___| |__  _| |_ ___  ___| |_ 
  | |/\| |/ _ \ '_ \  |  _  | '__/ __| '_ \| | __/ _ \/ __| __|
  \  /\  /  __/ |_) | | | | | | | (__| | | | | ||  __/ (__| |_ 
   \/  \/ \___|_.__/  \_| |_/_|  \___|_| |_|_|\__\___|\___|\__|
EOF
    echo -e "${RESET}"
    echo -e "    ${BOLD}${WHITE}Enterprise-Grade Web Scaffolding Platform${RESET}"
    echo -e "    ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

setup_project_metadata() {
  if [[ "${SILENT_MODE:-false}" != "true" ]]; then
    echo ""
    echo -en "  ${BOLD}${BLUE}?${RESET} ${BOLD}${WHITE}Project Name: ${RESET}${CYAN}"
    read -r input < /dev/tty
    PROJECT_NAME="${input:-my-web-app}"
    
    local loc_options=("Current Directory (./$PROJECT_NAME)" "Specific Path")
    local loc_choice=0
    select_option "Where should we architect this project?" "${loc_options[@]}" || loc_choice=$?
    
    if [[ $loc_choice -eq 0 ]]; then
      PROJECT_DIR="$(pwd)/$PROJECT_NAME"
    else
      echo -en "  ${BOLD}${BLUE}?${RESET} ${BOLD}${WHITE}Target Path: ${RESET}${CYAN}"
      read -r path_input < /dev/tty
      PROJECT_DIR="$path_input/$PROJECT_NAME"
    fi
  else
    PROJECT_NAME="${PROJECT_NAME:-test-app}"
    PROJECT_DIR="${PROJECT_DIR:-$(pwd)/$PROJECT_NAME}"
  fi
}

select_stack_and_engine() {
  if [[ "${SILENT_MODE:-false}" == "true" ]]; then
      # Default to Vue for silent mode/testing commands unless specified
      SELECTED_ENGINE="${SELECTED_ENGINE:-vue}"
      return
  fi

  log_header "Technology Stack Selection"
  
  local stack_options=("Frontend Application" "Backend Service" "Fullstack Application")
  local stack_choice=0
  select_option "What type of application are you building?" "${stack_options[@]}" || stack_choice=$?
  
  case $stack_choice in
    0) 
        PROJECT_TYPE="frontend" 
        local fe_options=("Vue.js (Ecosystem)" "React (Coming Soon)" "Angular (Coming Soon)" "Svelte (Coming Soon)")
        local fe_choice=0
        select_option "Select your Frontend Framework:" "${fe_options[@]}" || fe_choice=$?
        
        case $fe_choice in
            0) SELECTED_ENGINE="vue" ;;
            *) 
               log_warn "This framework is currently under development."
               log_info "Please check back later or contribute to the 'engines' directory!"
               exit 0 
               ;;
        esac
        ;;
    1) 
        PROJECT_TYPE="backend"
        log_warn "Backend scaffolding is under active development."
        exit 0
        ;;
    2) 
        PROJECT_TYPE="fullstack"
        log_warn "Fullstack scaffolding is under active development."
        exit 0
        ;;
  esac
}

load_engine_module() {
  local engine="$1"
  local engine_path="$ARCHITECT_ROOT/engines/$engine"
  
  if [[ ! -d "$engine_path" ]]; then
    fatal_error "Engine module '$engine' not found at engines/$engine"
  fi
  
  log_info "Loading engine module: ${BOLD}${engine}${RESET}..."
  
  # Source engine components
  [[ -f "$engine_path/constants.sh" ]] && source "$engine_path/constants.sh"
  [[ -f "$engine_path/actions.sh" ]] && source "$engine_path/actions.sh"
  [[ -f "$engine_path/generators.sh" ]] && source "$engine_path/generators.sh"
  [[ -f "$engine_path/utils.sh" ]] && source "$engine_path/utils.sh"
}

run_engine_lifecycle() {
    local phase="$1"
    local func_name="${SELECTED_ENGINE}_"
    
    case $phase in
        "menu") func_name+="engine_menu" ;;
        "initialize") func_name+="initialize_project" ;;
        "install") func_name+="install_dependencies" ;;
        "structure") func_name+="generate_structure" ;;
    esac
    
    if declare -f "$func_name" > /dev/null; then
        "$func_name"
    else
        log_warn "Engine '$SELECTED_ENGINE' does not implement lifecycle phase: $phase ($func_name)"
    fi
}

run_task_if_exists() {
    local task_name="$1"
    if declare -f "$task_name" > /dev/null; then
        "$task_name"
    fi
}

main
