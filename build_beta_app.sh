#!/opt/homebrew/bin/bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUILD_CHANNEL=beta "$script_dir/build_app.sh"
