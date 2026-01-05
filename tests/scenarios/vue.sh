#!/bin/bash

# --- Vue Scenarios ---

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

run_vue_tests() {
    export SELECTED_ENGINE="vue"
    # 1. Vite + JS (Standard)
    run_scaffold_test "vite-js-app" "vite" "false"

    # 2. Vite + TS
    run_scaffold_test "vite-ts-app" "vite" "true"

    # 3. Webpack + JS
    run_scaffold_test "webpack-js-app" "webpack" "false"

    # 4. Rollup + JS
    run_scaffold_test "rollup-js-app" "rollup" "false"

    # 5. Vite + TS + Vuetify
    export UI_LIBRARY="vuetify"
    run_scaffold_test "vite-vuetify-app" "vite" "true"
    unset UI_LIBRARY
}

run_vue_tests
