#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  install-agentic-knowledge.sh [--repo PATH] [--project-name NAME] [options]

Options:
  --repo PATH                 Target git repository. Default: current directory.
  --project-name NAME         Obsidian/GitNexus display name. Default: repo basename.
  --vault-root PATH           Obsidian vault root. Default: $HOME/Documents/Obsidian Vault.
  --obsidian-project-dir PATH Direct Obsidian project directory override.
  --skip-initial-run          Install files/hooks only; do not run GitNexus/graphify.
  --enable-embeddings         Opt in to GitNexus embeddings in install and post-commit hook.
  --no-claude                 Do not create Claude graphify hook/settings.
  --no-codex                  Do not create Codex graphify hook/settings.
  --no-gitnexus-skills        Run GitNexus without --skills.
  -h, --help                  Show this help.
USAGE
}

REPO="."
PROJECT_NAME=""
VAULT_ROOT="${HOME}/Documents/Obsidian Vault"
OBSIDIAN_PROJECT_DIR=""
SKIP_INITIAL_RUN=0
INSTALL_CLAUDE=1
INSTALL_CODEX=1
GITNEXUS_SKILLS=1
ENABLE_EMBEDDINGS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:?--repo requires a path}"
      shift 2
      ;;
    --project-name)
      PROJECT_NAME="${2:?--project-name requires a value}"
      shift 2
      ;;
    --vault-root)
      VAULT_ROOT="${2:?--vault-root requires a path}"
      shift 2
      ;;
    --obsidian-project-dir)
      OBSIDIAN_PROJECT_DIR="${2:?--obsidian-project-dir requires a path}"
      shift 2
      ;;
    --skip-initial-run)
      SKIP_INITIAL_RUN=1
      shift
      ;;
    --enable-embeddings)
      ENABLE_EMBEDDINGS=1
      shift
      ;;
    --no-claude)
      INSTALL_CLAUDE=0
      shift
      ;;
    --no-codex)
      INSTALL_CODEX=0
      shift
      ;;
    --no-gitnexus-skills)
      GITNEXUS_SKILLS=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$REPO" ]]; then
  echo "Repository path not found: $REPO" >&2
  exit 1
fi

cd "$REPO"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "Target is not inside a git repository: $REPO" >&2
  exit 1
fi
cd "$REPO_ROOT"

if [[ -z "$PROJECT_NAME" ]]; then
  PROJECT_NAME="$(basename "$REPO_ROOT")"
fi

mkdir -p scripts

write_text_file() {
  local path="$1"
  shift
  mkdir -p "$(dirname "$path")"
  cat > "$path"
}

replace_token() {
  local path="$1"
  local token="$2"
  local value="$3"
  python3 - "$path" "$token" "$value" <<'PY'
from pathlib import Path
import sys

path, token, value = sys.argv[1], sys.argv[2], sys.argv[3]
p = Path(path)
p.write_text(p.read_text().replace(token, value))
PY
}

update_block() {
  local path="$1"
  local start="$2"
  local end="$3"
  local body_file="$4"
  python3 - "$path" "$start" "$end" "$body_file" <<'PY'
from pathlib import Path
import sys

path, start, end, body_path = sys.argv[1:]
p = Path(path)
body = Path(body_path).read_text()
text = p.read_text() if p.exists() else ""
block = f"{start}\n{body.rstrip()}\n{end}\n"
if start in text and end in text:
    before = text.split(start, 1)[0].rstrip()
    after = text.split(end, 1)[1].lstrip()
    text = (before + "\n\n" if before else "") + block + ("\n" + after if after else "")
else:
    text = text.rstrip()
    text = (text + "\n\n" if text else "") + block
p.write_text(text)
PY
}

ensure_gitignore_line() {
  local line="$1"
  touch .gitignore
  grep -Fxq "$line" .gitignore || printf '%s\n' "$line" >> .gitignore
}

write_text_file scripts/post-commit-hook.sh <<'HOOK'
#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  exit 0
fi

cd "$REPO_ROOT" || exit 0

PROJECT_NAME="${AGENTIC_KNOWLEDGE_PROJECT_NAME:-__PROJECT_NAME__}"
ASYNC_MODE="${AGENTIC_KNOWLEDGE_HOOK_ASYNC:-1}"
HOOK_LOG_DIR="${AGENTIC_KNOWLEDGE_HOOK_LOG_DIR:-/tmp}"
ENABLE_EMBEDDINGS="${AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS:-__ENABLE_EMBEDDINGS__}"
LOCK_TIMEOUT_SECS="${AGENTIC_KNOWLEDGE_LOCK_TIMEOUT_SECS:-600}"
mkdir -p "$HOOK_LOG_DIR" 2>/dev/null || HOOK_LOG_DIR="/tmp"

COMMIT_HASH="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
COMMIT_MSG="$(git log -1 --pretty=%s 2>/dev/null || echo 'unknown commit')"
COMMIT_DATE="$(git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M' 2>/dev/null || date +'%Y-%m-%d %H:%M')"
MONTH_TAG="$(date +'%Y-%m')"

run_gitnexus_command() {
  if command -v gitnexus >/dev/null 2>&1; then
    gitnexus "$@"
    return $?
  fi
  if command -v npx >/dev/null 2>&1; then
    npx gitnexus "$@"
    return $?
  fi
  echo "[post-commit] GitNexus skipped: gitnexus/npx not found"
  return 0
}

run_gitnexus() {
  if [[ ! -d .gitnexus ]]; then
    echo "[post-commit] GitNexus skipped: .gitnexus is not initialized"
    return 0
  fi
  if ! run_gitnexus_command analyze --force --skip-agents-md; then
    echo "[post-commit] GitNexus non-embedding rebuild failed"
    return 0
  fi
  if [[ "$ENABLE_EMBEDDINGS" != "1" && "$ENABLE_EMBEDDINGS" != "true" ]]; then
    echo "[post-commit] GitNexus embeddings skipped: set AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS=1 to opt in"
    return 0
  fi
  if ! run_gitnexus_command analyze --embeddings --force --skip-agents-md; then
    echo "[post-commit] GitNexus embeddings failed; rebuilding without embeddings to keep the index usable"
    run_gitnexus_command analyze --force --skip-agents-md || true
  fi
}

acquire_gitnexus_lock() {
  local lock_dir=".gitnexus/post-commit.lock"
  local waited=0
  while ! mkdir "$lock_dir" 2>/dev/null; do
    if [[ -f "$lock_dir/pid" ]]; then
      local lock_pid
      lock_pid="$(cat "$lock_dir/pid" 2>/dev/null || true)"
      if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
        echo "[post-commit] Removing stale GitNexus lock held by pid $lock_pid"
        rm -rf "$lock_dir"
        continue
      fi
    fi
    if (( waited >= LOCK_TIMEOUT_SECS )); then
      echo "[post-commit] GitNexus skipped: lock wait timed out after ${LOCK_TIMEOUT_SECS}s"
      return 1
    fi
    sleep 1
    waited=$((waited + 1))
  done
  printf '%s\n' "$$" > "$lock_dir/pid"
}

release_gitnexus_lock() {
  rm -rf .gitnexus/post-commit.lock
}

run_gitnexus_locked() {
  if [[ ! -d .gitnexus ]]; then
    echo "[post-commit] GitNexus skipped: .gitnexus is not initialized"
    return 0
  fi
  acquire_gitnexus_lock || return 0
  run_gitnexus
  release_gitnexus_lock
}

run_graphify() {
  if [[ ! -d graphify-out ]]; then
    echo "[post-commit] graphify skipped: graphify-out is not initialized"
    return 0
  fi
  if ! command -v graphify >/dev/null 2>&1; then
    echo "[post-commit] graphify skipped: graphify not found"
    return 0
  fi
  graphify update .
}

write_obsidian_log() {
  local vault_root project_dir log_dir log_file
  if [[ -n "${OBSIDIAN_PROJECT_DIR:-}" ]]; then
    project_dir="$OBSIDIAN_PROJECT_DIR"
  else
    if [[ -n "${OBSIDIAN_VAULT:-}" ]]; then
      vault_root="$OBSIDIAN_VAULT"
    elif [[ -d "$HOME/Documents/Obsidian Vault" ]]; then
      vault_root="$HOME/Documents/Obsidian Vault"
    else
      vault_root="$HOME/Obsidian Vault"
    fi
    project_dir="$vault_root/$PROJECT_NAME"
  fi

  local project_parent
  project_parent="$(dirname "$project_dir")"
  if [[ ! -d "$project_parent" ]]; then
    echo "[post-commit] Obsidian skipped: vault parent not found at $project_parent"
    return 0
  fi

  log_dir="$project_dir/Development Logs"
  log_file="$log_dir/${MONTH_TAG} commit log.md"
  mkdir -p "$log_dir" || return 0

  if [[ ! -f "$log_file" ]]; then
    cat > "$log_file" <<EOF
# ${MONTH_TAG} commit log

Generated by \`scripts/post-commit-hook.sh\`.

Tags: #commit-log #${MONTH_TAG}

---

EOF
  fi

  if grep -Fq "\`${COMMIT_HASH}\`" "$log_file"; then
    echo "[post-commit] Obsidian already logged: $COMMIT_HASH"
    return 0
  fi

  printf -- "- \`%s\` (%s) - %s\n" "$COMMIT_HASH" "$COMMIT_DATE" "$COMMIT_MSG" >> "$log_file"
  echo "[post-commit] Obsidian logged: $log_file"
}

if [[ "$ASYNC_MODE" == "0" || "$ASYNC_MODE" == "false" ]]; then
  run_gitnexus_locked > "$HOOK_LOG_DIR/gitnexus-post-commit.log" 2>&1 || true
else
  (run_gitnexus_locked > "$HOOK_LOG_DIR/gitnexus-post-commit.log" 2>&1 &)
  echo "[post-commit] GitNexus analyze running in background"
fi

run_graphify > "$HOOK_LOG_DIR/graphify-post-commit.log" 2>&1 || true
write_obsidian_log || true
HOOK

replace_token scripts/post-commit-hook.sh "__PROJECT_NAME__" "$PROJECT_NAME"
replace_token scripts/post-commit-hook.sh "__ENABLE_EMBEDDINGS__" "$ENABLE_EMBEDDINGS"
chmod +x scripts/post-commit-hook.sh

write_text_file scripts/install-knowledge-hook.sh <<'HOOK'
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
HOOK
chmod +x scripts/install-knowledge-hook.sh

write_text_file scripts/test-post-commit-hook.sh <<'HOOK'
#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/scripts/post-commit-hook.sh"

if [[ ! -x "$SCRIPT_UNDER_TEST" ]]; then
  echo "missing executable hook script: $SCRIPT_UNDER_TEST" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

WORK_DIR="$TMP_DIR/work"
BIN_DIR="$TMP_DIR/bin"
LOG_DIR="$TMP_DIR/logs"
VAULT_DIR="$TMP_DIR/vault"

mkdir -p "$WORK_DIR/scripts" "$BIN_DIR" "$LOG_DIR" "$VAULT_DIR"
cp "$SCRIPT_UNDER_TEST" "$WORK_DIR/scripts/post-commit-hook.sh"

cat > "$BIN_DIR/gitnexus" <<'STUB'
#!/usr/bin/env bash
args="$*"
printf '%s\n' "$args" >> "$STUB_LOG_DIR/gitnexus.log"
if [[ "${STUB_GITNEXUS_FAIL_EMBEDDINGS:-0}" == "1" && "$args" == *"--embeddings"* ]]; then
  exit 42
fi
STUB

cat > "$BIN_DIR/graphify" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG_DIR/graphify.log"
STUB

cat > "$BIN_DIR/npx" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG_DIR/npx.log"
STUB

chmod +x "$BIN_DIR/gitnexus" "$BIN_DIR/graphify" "$BIN_DIR/npx"

cd "$WORK_DIR"
git init -q
git config user.email "hook-test@example.com"
git config user.name "Hook Test"
echo "hook test" > README.md
git add README.md
git commit -q -m "Hook test commit"
mkdir -p graphify-out .gitnexus

PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"

grep -F "analyze --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null
if [[ "ENABLE_EMBEDDINGS_PLACEHOLDER" == "1" ]]; then
  grep -F "analyze --embeddings --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null
else
  if grep -F -- "--embeddings" "$LOG_DIR/gitnexus.log" >/dev/null; then
    echo "embeddings should be opt-in by default" >&2
    exit 1
  fi
fi
grep -F "update ." "$LOG_DIR/graphify.log" >/dev/null

MONTH_TAG="$(date +'%Y-%m')"
OBSIDIAN_LOG="$VAULT_DIR/PROJECT_NAME_PLACEHOLDER/Development Logs/${MONTH_TAG} commit log.md"

grep -F "Hook test commit" "$OBSIDIAN_LOG" >/dev/null
grep -E -- '- `[0-9a-f]{7,}` \([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\) - Hook test commit' "$OBSIDIAN_LOG" >/dev/null

PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"

COUNT="$(grep -c "Hook test commit" "$OBSIDIAN_LOG")"
if [[ "$COUNT" != "1" ]]; then
  echo "expected one Obsidian log entry, got $COUNT" >&2
  exit 1
fi

: > "$LOG_DIR/gitnexus.log"
PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" STUB_GITNEXUS_FAIL_EMBEDDINGS=1 OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"

grep -F "analyze --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null

: > "$LOG_DIR/gitnexus.log"
PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" STUB_GITNEXUS_FAIL_EMBEDDINGS=1 OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS=1 AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"

grep -F "analyze --embeddings --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null
grep -F "analyze --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null

mkdir -p "$WORK_DIR/.gitnexus/post-commit.lock"
printf '999999\n' > "$WORK_DIR/.gitnexus/post-commit.lock/pid"
: > "$LOG_DIR/gitnexus.log"
PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"
grep -F "analyze --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null

echo "post-commit hook smoke test passed"
HOOK
replace_token scripts/test-post-commit-hook.sh "PROJECT_NAME_PLACEHOLDER" "$PROJECT_NAME"
replace_token scripts/test-post-commit-hook.sh "ENABLE_EMBEDDINGS_PLACEHOLDER" "$ENABLE_EMBEDDINGS"
chmod +x scripts/test-post-commit-hook.sh

write_text_file .gitnexusignore <<'IGNORE'
.worktrees/
notebooklm-mcp-setup/
node_modules/
.pnpm-store/
.venv/
venv/
env/
build/
dist/
.next/
.vite/
.cache/
coverage/
.pytest_cache/
.mypy_cache/
.ruff_cache/
htmlcov/
logs/
*.log
audio/
docker-data/
*.min.js
*.bundle.js
IGNORE

write_text_file .mcp.json <<'JSON'
{
  "mcpServers": {
    "gitnexus": {
      "command": "npx",
      "args": ["-y", "gitnexus@latest", "mcp"]
    }
  }
}
JSON

ensure_gitignore_line ""
ensure_gitignore_line "# Local code intelligence artifacts"
ensure_gitignore_line ".gitnexus/"
ensure_gitignore_line "graphify-out/"

mkdir -p .codex .claude
if [[ "$INSTALL_CODEX" == "1" ]]; then
  write_text_file .codex/hooks.json <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "graphify hook-check"
          }
        ]
      }
    ]
  }
}
JSON
fi

if [[ "$INSTALL_CLAUDE" == "1" ]]; then
  write_text_file .claude/settings.json <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "CMD=$(python3 -c \"import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',d).get('command',''))\" 2>/dev/null || true); case \"$CMD\" in *grep*|*rg\\ *|*ripgrep*|*find\\ *|*fd\\ *|*ack\\ *|*ag\\ *) [ -f graphify-out/graph.json ] && echo '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"graphify: Knowledge graph exists. Read graphify-out/GRAPH_REPORT.md before searching raw files.\"}}' || true ;; esac"
          }
        ]
      }
    ]
  }
}
JSON
fi

scripts/install-knowledge-hook.sh

tmp_block="$(mktemp)"
cat > "$tmp_block" <<EOF
## Agentic Knowledge Setup

This repo is wired for GitNexus, graphify, and Obsidian project memory.

- GitNexus MCP repo name: \`${PROJECT_NAME}\`
- graphify graph: \`graphify-out/\`
- Obsidian project logs: \`${OBSIDIAN_PROJECT_DIR:-${VAULT_ROOT}/${PROJECT_NAME}}/Development Logs/\`
- post-commit hook: \`scripts/post-commit-hook.sh\`

After commits, the hook serializes GitNexus with a repo-local lock, force-rebuilds the non-embedding GitNexus index, updates graphify, and appends the monthly Obsidian commit log. Embeddings are opt-in via \`AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS=1\` because some GitNexus/LadybugDB vector-index combinations can fail in native code; if embeddings fail, the hook force-rebuilds the non-embedding index so MCP remains usable.
EOF
update_block AGENTS.md "<!-- agentic-knowledge:start -->" "<!-- agentic-knowledge:end -->" "$tmp_block"
update_block CLAUDE.md "<!-- agentic-knowledge:start -->" "<!-- agentic-knowledge:end -->" "$tmp_block"
rm -f "$tmp_block"

if [[ "$SKIP_INITIAL_RUN" == "0" ]]; then
  if command -v gitnexus >/dev/null 2>&1 || command -v npx >/dev/null 2>&1; then
    if command -v gitnexus >/dev/null 2>&1; then
      GITNEXUS_CMD=(gitnexus)
    else
      GITNEXUS_CMD=(npx gitnexus)
    fi
    if [[ "$GITNEXUS_SKILLS" == "1" ]]; then
      "${GITNEXUS_CMD[@]}" analyze --skills || "${GITNEXUS_CMD[@]}" analyze
    else
      "${GITNEXUS_CMD[@]}" analyze
    fi
    "${GITNEXUS_CMD[@]}" analyze --force --skip-agents-md || true
    if [[ "$ENABLE_EMBEDDINGS" == "1" ]]; then
      "${GITNEXUS_CMD[@]}" analyze --embeddings --force --skip-agents-md || "${GITNEXUS_CMD[@]}" analyze --force --skip-agents-md || true
    fi
  else
    echo "GitNexus not found; install gitnexus or use npx before first indexing." >&2
  fi

  if command -v graphify >/dev/null 2>&1; then
    graphify update . || true
    [[ "$INSTALL_CODEX" == "1" ]] && graphify codex install || true
    [[ "$INSTALL_CLAUDE" == "1" ]] && graphify claude install || true
  else
    echo "graphify not found; install graphifyy/graphify before first graph build." >&2
  fi
fi

bash -n scripts/post-commit-hook.sh scripts/install-knowledge-hook.sh scripts/test-post-commit-hook.sh

echo "Agentic knowledge setup installed for ${PROJECT_NAME}"
echo "Target: ${REPO_ROOT}"
echo "Next verification: bash scripts/test-post-commit-hook.sh && gitnexus status && graphify update ."
