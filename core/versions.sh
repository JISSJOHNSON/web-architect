#!/bin/bash

# --- Core Version Management ---

select_version_profile() {
  local engine="$1"
  local engine_versions_dir="$ARCHITECT_ROOT/engines/$engine/versions"
  
  if [[ ! -d "$engine_versions_dir" ]]; then
    log_info "No specialized version profiles found for $engine. Using defaults."
    return
  fi

  local profiles=()
  
  # Prioritize Stable if it exists
  if [[ -f "$engine_versions_dir/stable.sh" ]]; then
    profiles+=("Stable")
  fi

  for f in "$engine_versions_dir"/*.sh; do
    local profile_name
    profile_name=$(basename "$f" .sh | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
    
    # Add if not already added (e.g., Stable)
    if [[ "$profile_name" != "Stable" ]]; then
      profiles+=("$profile_name")
    fi
  done
  profiles+=("Manual Override")

  log_header "Package Version Management"
  # Capture selection safely under set -o errexit
  local profile_choice=0
  select_option "Select a Version Profile" "${profiles[@]}" || profile_choice=$?
  
  local selected_profile_name="${profiles[$profile_choice]}"
  
  if [[ "$selected_profile_name" == "Manual Override" ]]; then
    manual_version_override
  else
    local profile_file="$engine_versions_dir/$(echo "$selected_profile_name" | tr '[:upper:]' '[:lower:]').sh"
    source "$profile_file"
    log_success "Profile '$selected_profile_name' loaded."
  fi
}

manual_version_override() {
  log_header "Manual Version Override"
  log_info "Leave empty to use 'latest'"
  
  echo -en "  ${BOLD}${BLUE}?${RESET} ${BOLD}${WHITE}Framework Version: ${RESET}${CYAN}"
  read -r FRAMEWORK_VERSION < /dev/tty
  [[ -z "$FRAMEWORK_VERSION" ]] && export FRAMEWORK_VERSION="latest" || export FRAMEWORK_VERSION="$FRAMEWORK_VERSION"
  # Backend compatibility for Vue engine
  export VUE_VERSION="$FRAMEWORK_VERSION"

  if [[ "$BUILD_TOOL" == "vite" ]]; then
    echo -en "  ${BOLD}${BLUE}?${RESET} ${BOLD}${WHITE}Vite Version: ${RESET}${CYAN}"
    read -r VITE_VERSION < /dev/tty
    [[ -z "$VITE_VERSION" ]] && export VITE_VERSION="latest" || export VITE_VERSION="$VITE_VERSION"
  fi

  if $USE_TAILWIND; then
    echo -en "  ${BOLD}${BLUE}?${RESET} ${BOLD}${WHITE}Tailwind Version: ${RESET}${CYAN}"
    read -r TAILWIND_VERSION < /dev/tty
    [[ -z "$TAILWIND_VERSION" ]] && export TAILWIND_VERSION="latest" || export TAILWIND_VERSION="$TAILWIND_VERSION"
  fi
}
