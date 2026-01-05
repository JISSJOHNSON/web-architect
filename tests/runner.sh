#!/bin/bash

# ==============================================================================
#  Web Architect Test Runner
#  ------------------------------------------------------------------------------
#  Executes all defined test scenarios found in the scenarios/ directory.
# ==============================================================================

set -o errexit
set -o nounset
set -o pipefail

# Setup Paths
TEST_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
export ARCHITECT_CMD="$PROJECT_ROOT/web-architect.command"
export TEST_ROOT="$PROJECT_ROOT/test_output"

# Argument Parsing
export CLEANUP_ON_SUCCESS=false
for arg in "$@"; do
    case $arg in
        --cleanup) CLEANUP_ON_SUCCESS=true ;;
    esac
done

# Utilities
source "$TEST_DIR/lib/utils.sh"

# Initialize
log_header "Initializing Test Suite..."
if $CLEANUP_ON_SUCCESS; then
    log_info "Cleanup enabled: Successful artifacts will be deleted."
fi
echo "Project Root: $PROJECT_ROOT"
echo "Test Output:  $TEST_ROOT"

# Cleanup
rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT"

# Run Scenarios
log_header "Running Scenarios..."

# Iterate through scenario scripts
for scenario in "$TEST_DIR/scenarios"/*.sh; do
    if [[ -f "$scenario" ]]; then
        log_header "Executing Suite: $(basename "$scenario")"
        # Run in a subshell to prevent env pollution between suites
        (source "$scenario")
    fi
done

log_header "All Test Suites Completed Successfully!"
echo -e "\nArtifacts are available in: $TEST_ROOT"
