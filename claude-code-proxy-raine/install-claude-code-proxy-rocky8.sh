#!/usr/bin/env bash
set -Eeuo pipefail

EXPECTED_OS=rocky
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=install-claude-code-proxy-common.sh
source "$SCRIPT_DIR/install-claude-code-proxy-common.sh" "$@"
