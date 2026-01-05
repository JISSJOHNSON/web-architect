#!/bin/bash

# ==============================================================================
#  Web Architect (Command Wrapper)
#  ------------------------------------------------------------------------------
#  Enables double-click execution on macOS.
# ==============================================================================

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# Execute the main architect script
if [[ -f "./architect.sh" ]]; then
    ./architect.sh
else
    echo "Error: architect.sh not found in $(pwd)"
    exit 1
fi
