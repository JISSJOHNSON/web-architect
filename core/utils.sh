#!/bin/bash

# --- Shared Utilities ---

check_command() {
  if ! command -v "$1" &> /dev/null; then
    fatal_error "Missing required command: $1"
  fi
}

validate_name() {
  if [[ ! "$1" =~ ^[a-z0-9_-]+$ ]]; then echo "invalid"; else echo "valid"; fi
}

get_timestamp() {
  date +%s
}

# --- Templating Engine ---
generate_from_template() {
  local template_path="$1"
  local output_path="$2"
  shift 2
  
  if [[ ! -f "$template_path" ]]; then
    fatal_error "Template not found: $template_path"
  fi

  local content
  content=$(cat "$template_path")
  
  while [[ $# -gt 0 ]]; do
    local key="$1"
    local value="$2"
    if command -v python3 &> /dev/null; then
      export CONTENT_VAL="$content"
      export KEY_VAL="$key"
      export VALUE_VAL="$value"
      content=$(python3 -c "import os, re; print(re.sub(r'\{\{\s*' + re.escape(os.environ['KEY_VAL']) + r'\s*\}\}', lambda m: os.environ['VALUE_VAL'], os.environ['CONTENT_VAL']), end='')")
    else
      content=$(echo "$content" | sed "s|{{$key}}|$value|g")
    fi
    shift 2
  done
  unset CONTENT_VAL KEY_VAL VALUE_VAL
  
  echo -n "$content" > "$output_path"
}
