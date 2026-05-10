#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SOURCE="$REPO_ROOT/scripts/post-commit-hook.sh"
HOOK_TARGET="$REPO_ROOT/.git/hooks/post-commit"

if [[ ! -d "$REPO_ROOT/.git/hooks" ]]; then
  echo "git hooks directory not found: $REPO_ROOT/.git/hooks" >&2
  exit 1
fi

chmod +x "$HOOK_SOURCE"
ln -sf "$HOOK_SOURCE" "$HOOK_TARGET"

echo "Installed post-commit hook:"
echo "  $HOOK_TARGET -> $HOOK_SOURCE"
