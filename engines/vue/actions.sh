# ==============================================================================
#  Vue Engine Actions
#  ------------------------------------------------------------------------------
#  Handles system-level tasks like dependency installation and directory setup.
# ==============================================================================

vue_initialize_project() {
  log_header "Core Foundation"
  npm init -y > /dev/null
  
  npm pkg set \
    name="$PROJECT_NAME" \
    version="0.1.0" \
    description="A modern Vue.js application architected for scale." \
    type="module" \
    author="Jiss Johnson (https://jissjohnson.info)" \
    homepage="https://jissjohnson.info" \
    license="MIT" \
    engines.node=">=18.0.0" \
    keywords="vue, $BUILD_TOOL, $UI_LIBRARY, pinia, architect" \
    architect.engine="vue" \
    architect.createdAt="$(date +"%Y-%m-%d %H:%M:%S")" \
    architect.features.typescript="$IS_TS" \
    architect.features.router="$USE_ROUTER" \
    architect.features.pinia="$USE_PINIA" \
    architect.features.ui_library="$UI_LIBRARY" \
    architect.features.tailwind="$USE_TAILWIND" \
    architect.features.eslint="$USE_ESLINT" \
    architect.features.prettier="$USE_PRETTIER" \
    architect.features.date_fns="$USE_DATE_LIB" \
    architect.features.numeral="$USE_NUMBER_LIB" \
    > /dev/null

  log_info "Manifest [package.json] initialized with Vue metadata"
}

vue_install_dependencies() {
  log_header "Dependency Harmonization"
  
  local core_msg="Standardizing Vue Core"
  if $USE_ROUTER; then core_msg="$core_msg + Navigation"; fi
  if $USE_PINIA; then core_msg="$core_msg + State"; fi
  
  start_spinner "$core_msg"
  local CORE_DEPS="vue@$VUE_VERSION axios"
  if $USE_ROUTER; then CORE_DEPS="$CORE_DEPS vue-router@$ROUTER_VERSION"; fi
  if $USE_PINIA; then CORE_DEPS="$CORE_DEPS pinia@$PINIA_VERSION"; fi
  if $USE_DATE_LIB; then CORE_DEPS="$CORE_DEPS date-fns"; fi
  if $USE_NUMBER_LIB; then CORE_DEPS="$CORE_DEPS numeral"; fi

  # UI Library Core Dependencies
  case $UI_LIBRARY in
    "vuetify") CORE_DEPS="$CORE_DEPS vuetify@latest" ;;
    "primevue") CORE_DEPS="$CORE_DEPS primevue@latest" ;;
    "element-plus") CORE_DEPS="$CORE_DEPS element-plus @element-plus/icons-vue" ;;
    "ant-design-vue") CORE_DEPS="$CORE_DEPS ant-design-vue@latest" ;;
    "bootstrap") CORE_DEPS="$CORE_DEPS bootstrap @popperjs/core" ;;
  esac

  npm install $CORE_DEPS --legacy-peer-deps > /dev/null 2>&1
  stop_spinner "Vue Core Runtime integrated"

  start_spinner "Configuring Development Environment ($BUILD_TOOL)"
  local DEV_DEPS=""
  
  case $BUILD_TOOL in
    "vite")
      DEV_DEPS="vite@$VITE_VERSION @vitejs/plugin-vue"
      ;;
    "webpack")
      DEV_DEPS="webpack webpack-cli webpack-dev-server vue-loader@latest css-loader vue-style-loader html-webpack-plugin babel-loader @babel/core @babel/preset-env ajv"
      ;;
    "rollup")
      DEV_DEPS="rollup @rollup/plugin-node-resolve @rollup/plugin-commonjs rollup-plugin-vue rollup-plugin-terser @rollup/plugin-alias rollup-plugin-postcss postcss"
      if $IS_TS; then DEV_DEPS="$DEV_DEPS @rollup/plugin-typescript tslib"; fi
      ;;
    "parcel")
      DEV_DEPS="parcel @parcel/transformer-vue"
      ;;
  esac
  
  if $USE_TAILWIND; then 
    DEV_DEPS="$DEV_DEPS tailwindcss@$TAILWIND_VERSION postcss autoprefixer"
    if [[ "$BUILD_TOOL" == "webpack" ]]; then DEV_DEPS="$DEV_DEPS postcss-loader"; fi
  fi

  # UI Library Dev Dependencies
  case $UI_LIBRARY in
    "vuetify") 
      DEV_DEPS="$DEV_DEPS sass"
      if [[ "$BUILD_TOOL" == "vite" ]]; then DEV_DEPS="$DEV_DEPS vite-plugin-vuetify"; fi
      ;;
    "bootstrap")
      DEV_DEPS="$DEV_DEPS sass"
      ;;
  esac
  if $USE_ESLINT; then DEV_DEPS="$DEV_DEPS eslint@$ESLINT_VERSION eslint-plugin-vue globals"; fi
  if $USE_PRETTIER; then DEV_DEPS="$DEV_DEPS prettier@$PRETTIER_VERSION"; fi
  if [[ "$USE_ESLINT" == "true" && "$USE_PRETTIER" == "true" ]]; then DEV_DEPS="$DEV_DEPS @vue/eslint-config-prettier"; fi
  
  if $IS_TS; then
    DEV_DEPS="$DEV_DEPS typescript vue-tsc @types/node @vue/tsconfig"
    if $USE_ESLINT; then DEV_DEPS="$DEV_DEPS @vue/eslint-config-typescript"; fi
    if [[ "$BUILD_TOOL" == "webpack" ]]; then DEV_DEPS="$DEV_DEPS ts-loader"; fi
  fi

  npm install -D $DEV_DEPS --legacy-peer-deps > /dev/null 2>&1
  stop_spinner "Development ecosystem ready"
}

vue_generate_structure() {
  log_header "Scaffolding Vue Architecture"
  local dirs=(
    "src/api" "src/assets/images" "src/assets/styles"
    "src/components/base" "src/components/common" "src/components/features"
    "src/composables" "src/constants" "src/directives"
    "src/helpers" "src/layouts" "src/router/guards"
    "src/services" "src/stores" "src/types"
    "src/utils" "src/views"
  )
  for dir in "${dirs[@]}"; do mkdir -p "$dir"; done
  log_success "Vue directory structure created"
}

update_scripts() {
  log_info "Synchronizing specialized scripts for $BUILD_TOOL..."
  
  # Base Scripts
  case $BUILD_TOOL in
    "vite")
      npm pkg set scripts.dev="vite" scripts.build="vite build" scripts.preview="vite preview" > /dev/null
      ;;
    "webpack")
      npm pkg set scripts.dev="webpack serve --mode development" scripts.build="webpack --mode production" > /dev/null
      ;;
    "rollup")
      npm pkg set scripts.dev="rollup -c -w" scripts.build="rollup -c" > /dev/null
      ;;
    "parcel")
      npm pkg set scripts.dev="parcel src/index.html" scripts.build="parcel build src/index.html" > /dev/null
      ;;
  esac
  
  # Type Checking
  if $IS_TS; then
      npm pkg set scripts.type-check="vue-tsc --noEmit" > /dev/null
      if [[ "$BUILD_TOOL" == "vite" ]]; then
          npm pkg set scripts.build="npm run type-check && vite build" > /dev/null
      fi
  fi
  
  # Linting & Formatting
  if $USE_ESLINT; then
      npm pkg set \
        scripts.lint="eslint . --fix" \
        scripts.lint:check="eslint ." \
        > /dev/null
  fi
  
  if $USE_PRETTIER; then
      npm pkg set \
        scripts.format="prettier --write ." \
        scripts.format:check="prettier --check ." \
        > /dev/null
  fi
  
  # Composite Scripts
  if [[ "$USE_ESLINT" == "true" && "$USE_PRETTIER" == "true" ]]; then
      npm pkg set scripts.verify="npm run lint:check && npm run format:check" > /dev/null
  fi
}
