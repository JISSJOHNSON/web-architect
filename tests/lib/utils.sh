#!/bin/bash

# --- Test Utilities ---

# Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

log_header() { echo -e "\n${BOLD}${MAGENTA}==>${RESET} ${BOLD}${WHITE}$1${RESET}"; }
log_info() { echo -e "  ${BLUE}ℹ${RESET}  $1"; }
log_success() { echo -e "  ${GREEN}✓${RESET}  $1"; }
log_warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
log_error() { echo -e "  ${RED}✖${RESET}  $1"; }

# Common Test Runner Logic
run_scaffold_test() {
    local name="$1"
    local build_tool="$2"
    local is_ts="$3"
    
    log_header "Testing Scenario: $name (Tool: $build_tool, TS: $is_ts)"
    
    # Export params for the Architect
    export SILENT_MODE="true"
    export PROJECT_NAME="$name"
    export PROJECT_DIR="$TEST_ROOT/$name"
    export BUILD_TOOL="$build_tool"
    export IS_TS="$is_ts"
    
    # Run scaffolding
    # We assume ARCHITECT_CMD is exported by the runner
    bash "$ARCHITECT_CMD" > /dev/null
    
    # Check if project was created
    if [[ -d "$PROJECT_DIR" ]]; then
        log_success "Scaffolded successfully"
    else
        log_error "Project directory not created"
        exit 1
    fi
    
    # Check for build tool specific config
    case $build_tool in
        "vite") [[ -f "$PROJECT_DIR/vite.config.js" || -f "$PROJECT_DIR/vite.config.ts" ]] && log_success "Vite config found" ;;
        "webpack") [[ -f "$PROJECT_DIR/webpack.config.cjs" ]] && log_success "Webpack config found" ;;
        "rollup") [[ -f "$PROJECT_DIR/rollup.config.js" || -f "$PROJECT_DIR/rollup.config.mjs" ]] && log_success "Rollup config found" ;;
    esac
    
    # Run npm install & build
    log_header "Building: $name"
    cd "$PROJECT_DIR" || exit 1
    
    # Install
    if npm install --legacy-peer-deps > /dev/null 2>&1; then
        log_success "Dependencies installed"
    else
        log_error "Dependency installation failed"
        exit 1
    fi

    # Build
    if npm run build > /dev/null 2>&1; then
        log_success "Build completed successfully"
    else
        log_error "Build failed"
        exit 1
    fi

    # Smoke test: Start dev server
    log_header "Dev Server Smoke Test: $name"
    npm run dev > dev_server.log 2>&1 &
    DEV_PID=$!
    
    # Wait for a few seconds to let it crash if it's going to
    sleep 7
    
    if kill -0 $DEV_PID 2>/dev/null; then
        kill $DEV_PID
        log_success "Dev server started successfully (smoke test passed)"
    else
        # If it's not running, check exit code
        wait $DEV_PID || local exit_code=$?
        if [[ ${exit_code:-0} -eq 0 ]]; then
             log_success "Dev server finished/started (smoke test passed-exit 0)"
        else
             log_warn "Dev server failed to start. Log output:"
             cat dev_server.log
             exit 1
        fi
    fi
    
    # Cleanup if requested
    if [[ "${CLEANUP_ON_SUCCESS:-false}" == "true" ]]; then
        log_info "Cleaning up artifacts..."
        rm -rf "$PROJECT_DIR"
    fi
    
    # Return to test root
    cd "$TEST_ROOT" || exit 1
}
