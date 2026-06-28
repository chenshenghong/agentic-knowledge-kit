#!/usr/bin/env bash

set -euo pipefail

INSTALLER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
  --enable-embeddings         Opt in to GitNexus embeddings for the initial index (GitNexus is not in the post-commit hook).
  --skip-vector-deps          Do not install isolated LanceDB dependencies under scripts/node_modules.
  --no-claude                 Do not create Claude graphify hook/settings.
  --no-codex                  Do not create Codex graphify hook/settings.
  --no-antigravity            Do not create Antigravity/Gemini rules.
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
INSTALL_ANTIGRAVITY=1
GITNEXUS_SKILLS=1
ENABLE_EMBEDDINGS=0
SKIP_VECTOR_DEPS=0

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
    --skip-vector-deps)
      SKIP_VECTOR_DEPS=1
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
    --no-antigravity)
      INSTALL_ANTIGRAVITY=0
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
mkdir -p raw wiki/concepts wiki/entities wiki/sources

copy_helper_script() {
  local name="$1"
  local src="$INSTALLER_ROOT/scripts/$name"
  local dst="scripts/$name"
  if [[ ! -f "$src" ]]; then
    echo "Missing helper script in installer: $src" >&2
    exit 1
  fi
  if [[ ! -f "$dst" ]] || ! cmp -s "$src" "$dst"; then
    cp "$src" "$dst"
  fi
}

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

copy_helper_script semantic-vector-lib.mjs
copy_helper_script build-semantic-vector-index.mjs
copy_helper_script query-semantic-vector-index.mjs
copy_helper_script agentic-knowledge-context.mjs
copy_helper_script llm-wiki-lib.mjs
copy_helper_script ingest-llm-wiki.mjs
copy_helper_script lint-llm-wiki.mjs
copy_helper_script test-semantic-vector-index.mjs
copy_helper_script test-llm-wiki-workflow.mjs
copy_helper_script install-vector-deps.sh
copy_helper_script gitnexus-fresh.sh
copy_helper_script install-cmm.sh
copy_helper_script gitnexus-gate.sh
chmod +x scripts/build-semantic-vector-index.mjs scripts/query-semantic-vector-index.mjs scripts/agentic-knowledge-context.mjs scripts/ingest-llm-wiki.mjs scripts/lint-llm-wiki.mjs scripts/test-semantic-vector-index.mjs scripts/test-llm-wiki-workflow.mjs scripts/install-vector-deps.sh scripts/gitnexus-fresh.sh scripts/install-cmm.sh scripts/gitnexus-gate.sh

if [[ "$SKIP_VECTOR_DEPS" == "0" ]]; then
  scripts/install-vector-deps.sh || echo "LanceDB dependency install failed; semantic vector build will log a skip/failure until dependencies are installed." >&2
fi

copy_helper_script post-commit-hook.sh

# The copied hook ships with a repo-basename PROJECT_NAME fallback; bake the
# chosen --project-name in so the Obsidian vault path / vector --project match.
replace_token scripts/post-commit-hook.sh '$(basename "$REPO_ROOT")' "$PROJECT_NAME"
chmod +x scripts/post-commit-hook.sh

write_text_file scripts/install-knowledge-hook.sh <<'HOOK'
#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SOURCE="$REPO_ROOT/scripts/post-commit-hook.sh"
COMMON_GIT_DIR="$(git -C "$REPO_ROOT" rev-parse --git-common-dir 2>/dev/null || true)"

if [[ -z "$COMMON_GIT_DIR" ]]; then
  echo "git common directory not found for $REPO_ROOT" >&2
  exit 1
fi

case "$COMMON_GIT_DIR" in
  /*) HOOK_DIR="$COMMON_GIT_DIR/hooks" ;;
  *) HOOK_DIR="$REPO_ROOT/$COMMON_GIT_DIR/hooks" ;;
esac

HOOK_TARGET="$HOOK_DIR/post-commit"

if [[ ! -d "$HOOK_DIR" ]]; then
  echo "git hooks directory not found: $HOOK_DIR" >&2
  exit 1
fi

chmod +x "$HOOK_SOURCE"
ln -sf "$HOOK_SOURCE" "$HOOK_TARGET"

echo "Installed post-commit hook:"
echo "  $HOOK_TARGET -> $HOOK_SOURCE"
HOOK
chmod +x scripts/install-knowledge-hook.sh

copy_helper_script test-post-commit-hook.sh
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

if [[ -f .cbmignore ]]; then
  echo "[install] .cbmignore exists — keeping project-custom excludes"
else
  write_text_file .cbmignore <<'CBM'
# codebase-memory-mcp ignore — exclude vendored/decompiled/build noise.
# Keep docs/ + markdown. Mirror your .gitignore's vendored dirs here.
**/vendor/
legacy_reference/
node_modules/
dist/
build/
.next/
.venv/
venv/
coverage/
**/backups/
CBM
fi

write_text_file .mcp.json <<'JSON'
{
  "mcpServers": {
    "gitnexus": {
      "command": "npx",
      "args": ["-y", "gitnexus@latest", "mcp"]
    },
    "codebase-memory-mcp": {
      "command": "codebase-memory-mcp",
      "args": []
    }
  }
}
JSON

ensure_gitignore_line ""
ensure_gitignore_line "# Local code intelligence artifacts"
ensure_gitignore_line ".gitnexus/"
ensure_gitignore_line "graphify-out/"
ensure_gitignore_line "semantic-vector-index/"
ensure_gitignore_line "scripts/node_modules/"

# Ensure the codebase-memory-mcp (CMM) code engine is installed + MCP-registered on this machine.
if [[ "${SKIP_CMM:-0}" != "1" ]]; then
  bash scripts/install-cmm.sh || echo "[install] CMM bootstrap reported issues (non-fatal); run scripts/install-cmm.sh manually." >&2
fi

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
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "graphify update . >/dev/null 2>&1 || true"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "graphify check-update ."
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
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "[ -f scripts/agentic-knowledge-context.mjs ] && node scripts/agentic-knowledge-context.mjs --limit ${AGENTIC_KNOWLEDGE_CONTEXT_LIMIT:-5} || true"
          }
        ]
      }
    ],
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
  # Merge the GitNexus staleness-gate PreToolUse hook (idempotent): impact/rename/
  # detect_changes auto-refresh a stale index at point-of-use (no one must remember).
  python3 - <<'PY'
import json
p='.claude/settings.json'
try:
    d=json.load(open(p))
except Exception:
    raise SystemExit(0)
arr=d.setdefault('hooks',{}).setdefault('PreToolUse',[])
m='mcp__gitnexus__(impact|rename|detect_changes)'
if not any(x.get('matcher')==m for x in arr):
    arr.append({'matcher':m,'hooks':[{'type':'command','command':'bash scripts/gitnexus-gate.sh','timeout':120}]})
    json.dump(d, open(p,'w'), indent=2); open(p,'a').write('\n')
PY
fi

scripts/install-knowledge-hook.sh

tmp_block="$(mktemp)"
cat > "$tmp_block" <<'EOF'
## Agentic Knowledge Setup

This repo is wired for codebase-memory-mcp (CMM, code engine), GitNexus
(on-demand edit-safety), graphify, LanceDB doc retrieval, and Obsidian memory.

**知識系統分層（按資料型態切 4 個鬆耦合引擎）：**
- **程式碼導航/搜尋 → CMM**（`codebase-memory-mcp` MCP，每 commit ~0.5s 增量；`.cbmignore` 排噪音）。每日程式碼主引擎。
- **改碼安全（impact 風險/PDG taint/rename/detect_changes vs base）→ GitNexus**：`impact`/`rename`/`detect_changes`（MCP）前由 PreToolUse gate `scripts/gitnexus-gate.sh` **自動刷新**過時索引（fresh 時 ~30ms no-op，不靠記憶）；`explain` PDG taint 需手動 `AGENTIC_KNOWLEDGE_PDG=1 bash scripts/gitnexus-fresh.sh`。
- **文件/決策/根因召回 → broker（docs-only LanceDB ＋ Obsidian vault，含中文）**，每次提問自動注入。
- **跨域/多模態 → graphify**；人類記憶 → Obsidian。CMM 不吃文件/中文、無 rename、無 risk 分級。

- CMM (code graph): `codebase-memory-mcp` MCP; per-machine bootstrap `bash scripts/install-cmm.sh`; excludes via `.cbmignore`
- GitNexus MCP — **on-demand**: `bash scripts/gitnexus-fresh.sh` (taint: `AGENTIC_KNOWLEDGE_PDG=1`)
- graphify graph: `graphify-out/`
- doc vector index: `semantic-vector-index/lancedb` (docs-only + Obsidian); rebuild `node scripts/build-semantic-vector-index.mjs --docs-only --obsidian`
- task context broker: `node scripts/agentic-knowledge-context.mjs "<task>"`
- post-commit hook: `scripts/post-commit-hook.sh` (CMM incremental + graphify + docs-only vector + Obsidian log; GitNexus NOT in hook)

### Retrieval Protocol

At task start, consume the broker (auto-injected for Claude via UserPromptSubmit):

```bash
node scripts/agentic-knowledge-context.mjs "<task summary>" --limit "${AGENTIC_KNOWLEDGE_CONTEXT_LIMIT:-5}"
```

The broker returns doc/decision/root-cause matches (repo docs + Obsidian vault, incl. Chinese) — not code. Then: code structure/search → **CMM**; edit-safety → **GitNexus** (a PreToolUse gate auto-refreshes a stale index before impact/rename/detect_changes; explain/PDG taint needs manual `AGENTIC_KNOWLEDGE_PDG=1`); cross-module relations → **graphify**. Verify exact behavior in source/tests before editing.
EOF
update_block AGENTS.md "<!-- agentic-knowledge:start -->" "<!-- agentic-knowledge:end -->" "$tmp_block"
update_block CLAUDE.md "<!-- agentic-knowledge:start -->" "<!-- agentic-knowledge:end -->" "$tmp_block"
if [[ "$INSTALL_ANTIGRAVITY" == "1" ]]; then
  update_block GEMINI.md "<!-- agentic-knowledge:start -->" "<!-- agentic-knowledge:end -->" "$tmp_block"
fi
rm -f "$tmp_block"

if [[ "$INSTALL_ANTIGRAVITY" == "1" ]]; then
  mkdir -p .agents/rules .agent/rules
  write_text_file .agents/rules/agentic-knowledge.md <<'RULE'
# Agentic Knowledge Retrieval

知識系統分層（按資料型態切）：
- 程式碼導航/搜尋 → **CMM**（codebase-memory-mcp MCP）。每日程式碼主引擎。
- 改碼安全 → **GitNexus**：impact/rename/detect_changes 前由 PreToolUse gate 自動刷新過時索引；explain/PDG taint 手動 `AGENTIC_KNOWLEDGE_PDG=1`。
- 文件/決策/根因召回 → broker（docs-only + Obsidian vault，含中文），task 開始時查：

```bash
node scripts/agentic-knowledge-context.mjs "<task summary>" --limit "${AGENTIC_KNOWLEDGE_CONTEXT_LIMIT:-5}"
```

- 跨域關係 → graphify。Verify exact behavior in source/tests before editing. CMM 不吃文件/中文、無 rename、無 risk 分級。

For LLM Wiki: read immutable material from `raw/`, write synthesis under `wiki/`, run `node scripts/lint-llm-wiki.mjs --strict` before treating wiki notes as clean.
RULE
  cp .agents/rules/agentic-knowledge.md .agent/rules/agentic-knowledge.md
fi

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
    if command -v node >/dev/null 2>&1; then
      node scripts/build-semantic-vector-index.mjs --docs-only --obsidian --project "$PROJECT_NAME" || true
    else
      echo "node not found; semantic vector index will be built by the hook when node is available." >&2
    fi
    [[ "$INSTALL_CODEX" == "1" ]] && graphify codex install || true
    [[ "$INSTALL_CLAUDE" == "1" ]] && graphify claude install || true
  else
    echo "graphify not found; install graphifyy/graphify before first graph build." >&2
  fi
fi

bash -n scripts/post-commit-hook.sh scripts/install-knowledge-hook.sh scripts/test-post-commit-hook.sh

echo "Agentic knowledge setup installed for ${PROJECT_NAME}"
echo "Target: ${REPO_ROOT}"
echo "Next verification: bash scripts/test-post-commit-hook.sh && node scripts/test-semantic-vector-index.mjs && node scripts/test-llm-wiki-workflow.mjs && gitnexus status && graphify update ."
