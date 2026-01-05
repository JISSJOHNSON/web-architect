#!/bin/bash

# ==============================================================================
#  Web Architect Test Wrapper
#  ------------------------------------------------------------------------------
#  Convenience script to launch the full test suite.
# ==============================================================================

# Delegate to the modular test runner
bash "$(dirname "$0")/tests/runner.sh" "$@"
