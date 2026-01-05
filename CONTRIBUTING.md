# Contributing to Vue Architect

First off, thank you for considering contributing to Vue Architect! This project is designed to be a scalable foundation for modern Vue development, and your contributions help make it better for everyone.

## 🌟 How Can I Contribute?

### Reporting Bugs
- Search existing [Issues](https://github.com/jissjohnson/vue-architect/issues).
- If not found, open a new issue with a clear description, reproduction steps, and expected behavior.

### Suggesting Enhancements
- Open a GitHub Issue and explain the feature you want to see.
- Explain why this feature would be useful to most users.

---

## 🏗️ Technical Architecture

The platform is divided into three logical layers:

### 1. Core Layer (`core/`)
- **`ui.sh`**: Shared UI components and color logic.
- **`utils.sh`**: Common utilities (spinners, name validation).
- **`init.sh`**: Lifecycle hooks (directory setup, git init).
- **`versions.sh`**: The package version management logic.

### 2. Vue Engine Layer (`engines/vue/`)
Encapsulates all logic specific to Vue.js:
- **`constants.sh`**: Vue state and dependency lists.
- **`actions.sh`**: Dependency installation and structure logic.
- **`generators.sh`**: Logic for deciding which templates to use.
- **`versions/`**: Profile definitions (stable.sh, latest.sh, etc.).

### 3. Resource Layer (`resources/vue/`)
- Contains the actual boilerplate files, Vue components, and configuration templates.

---

## 📝 Pull Request Process

1. **Setup**: Ensure you have Bash, Node.js v18+, and Git.
2. **Branch**: Create a feature branch from `main`.
3. **Test**: Run `./architect.sh` to verify your changes.
4. **Style**: 
   - Use `local` variables in functions.
   - Use `"${VARIABLE}"` for expansion.
   - Use core logging functions (`log_info`, `log_success`, etc.).

---

## ☕ Support

Reach out via [GitHub Issues](https://github.com/jissjohnson/vue-architect/issues) or support the project via [Buy Me A Coffee](https://www.buymeacoffee.com/jissjohnson).

---
Happy architecting! 🚀
