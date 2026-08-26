#!/opt/homebrew/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

local_path_pattern='/Users/|/Volumes/|/private/|\bmartin\b'
secret_pattern='ghp_[A-Za-z0-9]+|github_pat_|api[_-]?key[[:space:]]*[:=]|secret[[:space:]]*[:=]|token[[:space:]]*[:=]|password[[:space:]]*[:=]|BEGIN (RSA|OPENSSH) PRIVATE KEY'

local_path_matches="$(rg -n -i "$local_path_pattern" --glob '!Build/**' --glob '!.build/**' --glob '!dist/**' --glob '!.git/**' --glob '!Scripts/privacy-check.sh' --glob '!Scripts/build-release-package.sh' . || true)"
disallowed_local_path_matches="$(printf '%s\n' "$local_path_matches" | awk '$0 !~ /\/Users\/example\// && $0 !~ /~\/Library\/Application Support\/AppName\//')"
if [[ -n "$disallowed_local_path_matches" ]]; then
  printf '%s\n' "$disallowed_local_path_matches"
  echo 'Privacy check failed: local path or private identifier found.' >&2
  exit 1
fi

if rg -n -i "$secret_pattern" --glob '!Build/**' --glob '!.build/**' --glob '!dist/**' --glob '!.git/**' --glob '!Scripts/privacy-check.sh' --glob '!Scripts/build-release-package.sh' .; then
  echo 'Privacy check failed: credential-like content found.' >&2
  exit 1
fi

echo 'Privacy check passed.'
