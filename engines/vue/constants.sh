#!/bin/bash

# --- Vue Engine Constants ---

# Defaults (can be overridden by version profiles)
export VUE_VERSION="${VUE_VERSION:-^3.4.0}"
export VITE_VERSION="${VITE_VERSION:-^5.0.0}"
export TAILWIND_VERSION="${TAILWIND_VERSION:-^3.4.1}"
export PINIA_VERSION="${PINIA_VERSION:-^2.1.0}"
export ROUTER_VERSION="${ROUTER_VERSION:-^4.3.0}"
export ESLINT_VERSION="${ESLINT_VERSION:-^8.56.0}"
export PRETTIER_VERSION="${PRETTIER_VERSION:-^3.2.0}"
export UI_LIBRARY_VERSION="${UI_LIBRARY_VERSION:-latest}"

# Vue Engine State
IS_TS="${IS_TS:-false}"
BUILD_TOOL="${BUILD_TOOL:-vite}"
USE_ROUTER="${USE_ROUTER:-true}"
USE_PINIA="${USE_PINIA:-true}"
UI_LIBRARY="${UI_LIBRARY:-tailwind}"
USE_TAILWIND="${USE_TAILWIND:-true}"
USE_ESLINT="${USE_ESLINT:-true}"
USE_PRETTIER="${USE_PRETTIER:-true}"
USE_DATE_LIB="${USE_DATE_LIB:-false}"
USE_NUMBER_LIB="${USE_NUMBER_LIB:-false}"

vue_engine_menu() {
  echo ""
  local tools=("Vite (Recommended)" "Webpack" "Rollup" "Parcel")
  local tool_choice=0
  select_option "Select Build Tool:" "${tools[@]}" || tool_choice=$?
  case $tool_choice in
    0) BUILD_TOOL="vite" ;;
    1) BUILD_TOOL="webpack" ;;
    2) BUILD_TOOL="rollup" ;;
    3) BUILD_TOOL="parcel" ;;
  esac

  echo ""
  local langs=("JavaScript" "TypeScript")
  local lang_choice=0
  select_option "Select Development Language:" "${langs[@]}" || lang_choice=$?
  [[ $lang_choice -eq 1 ]] && IS_TS=true || IS_TS=false

  echo ""
  local ui_libs=("Tailwind CSS" "Vuetify" "PrimeVue" "Element Plus" "Ant Design Vue" "Bootstrap" "None")
  local ui_choice=0
  select_option "Select UI Library:" "${ui_libs[@]}" || ui_choice=$?
  case $ui_choice in
    0) UI_LIBRARY="tailwind" ; USE_TAILWIND=true ;;
    1) UI_LIBRARY="vuetify" ; USE_TAILWIND=false ;;
    2) UI_LIBRARY="primevue" ; USE_TAILWIND=false ;;
    3) UI_LIBRARY="element-plus" ; USE_TAILWIND=false ;;
    4) UI_LIBRARY="ant-design-vue" ; USE_TAILWIND=false ;;
    5) UI_LIBRARY="bootstrap" ; USE_TAILWIND=false ;;
    6) UI_LIBRARY="none" ; USE_TAILWIND=false ;;
  esac

  echo ""
  local features=("Vue Router" "Pinia (State Management)" "ESLint" "Prettier" "Date Utils (date-fns)" "Currency Utils (numeral)")
  export DEFAULT_SELECTION="true"
  local results=($(select_multiple "Select Project Features:" "${features[@]}"))
  unset DEFAULT_SELECTION
  
  USE_ROUTER="${results[0]}"
  USE_PINIA="${results[1]}"
  USE_ESLINT="${results[2]}"
  USE_PRETTIER="${results[3]}"
  USE_DATE_LIB="${results[4]}"
  USE_NUMBER_LIB="${results[5]}"
}
