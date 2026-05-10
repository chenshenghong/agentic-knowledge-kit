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
cp "$REPO_ROOT/scripts/semantic-vector-lib.mjs" "$WORK_DIR/scripts/semantic-vector-lib.mjs"
cp "$REPO_ROOT/scripts/build-semantic-vector-index.mjs" "$WORK_DIR/scripts/build-semantic-vector-index.mjs"
cp "$REPO_ROOT/scripts/query-semantic-vector-index.mjs" "$WORK_DIR/scripts/query-semantic-vector-index.mjs"
cp "$REPO_ROOT/scripts/agentic-knowledge-context.mjs" "$WORK_DIR/scripts/agentic-knowledge-context.mjs"
cp "$REPO_ROOT/scripts/install-vector-deps.sh" "$WORK_DIR/scripts/install-vector-deps.sh"
chmod +x "$WORK_DIR/scripts/install-vector-deps.sh"

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
mkdir -p src graphify-out
cat > src/audio.js <<'JS'
export function mixVirtualAudio(systemAudio, microphone) {
  return [systemAudio, microphone].filter(Boolean).join(" + ");
}
JS
cat > graphify-out/graph.json <<'JSON'
{
  "directed": true,
  "graph": {},
  "nodes": [
    {
      "id": "mixVirtualAudio",
      "label": "mixVirtualAudio",
      "source_file": "src/audio.js",
      "source_location": "src/audio.js:1",
      "community": 1,
      "file_type": "javascript"
    }
  ],
  "links": []
}
JSON
git add README.md
git commit -q -m "Hook test commit"
mkdir -p .gitnexus
"$WORK_DIR/scripts/install-vector-deps.sh" >/dev/null

PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"

grep -F "analyze --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null
if [[ "0" == "1" ]]; then
  grep -F "analyze --embeddings --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null
else
  if grep -F -- "--embeddings" "$LOG_DIR/gitnexus.log" >/dev/null; then
    echo "embeddings should be opt-in by default" >&2
    exit 1
  fi
fi
grep -F "update ." "$LOG_DIR/graphify.log" >/dev/null
test -f "$WORK_DIR/semantic-vector-index/manifest.json"
test -d "$WORK_DIR/semantic-vector-index/lancedb"
node -e 'const fs=require("fs"); const p=process.argv[1]; const idx=JSON.parse(fs.readFileSync(p,"utf8")); if (idx.provider.name !== "test" || idx.store.kind !== "lancedb" || idx.source.indexedItemCount !== 1) process.exit(1);' "$WORK_DIR/semantic-vector-index/manifest.json"
CONTEXT_OUT="$(AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test node "$WORK_DIR/scripts/agentic-knowledge-context.mjs" --repo "$WORK_DIR" --provider test "virtual audio mixer")"
grep -F "Agentic Knowledge Context" <<< "$CONTEXT_OUT" >/dev/null
grep -F "mixVirtualAudio" <<< "$CONTEXT_OUT" >/dev/null

MONTH_TAG="$(date +'%Y-%m')"
OBSIDIAN_LOG="$VAULT_DIR/agentic-knowledge-kit/Development Logs/${MONTH_TAG} commit log.md"

grep -F "Hook test commit" "$OBSIDIAN_LOG" >/dev/null
grep -E -- '- `[0-9a-f]{7,}` \([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\) - Hook test commit' "$OBSIDIAN_LOG" >/dev/null

PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"

COUNT="$(grep -c "Hook test commit" "$OBSIDIAN_LOG")"
if [[ "$COUNT" != "1" ]]; then
  echo "expected one Obsidian log entry, got $COUNT" >&2
  exit 1
fi

: > "$LOG_DIR/gitnexus.log"
PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" STUB_GITNEXUS_FAIL_EMBEDDINGS=1 OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"

grep -F "analyze --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null

: > "$LOG_DIR/gitnexus.log"
PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" STUB_GITNEXUS_FAIL_EMBEDDINGS=1 OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS=1 AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"

grep -F "analyze --embeddings --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null
grep -F "analyze --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null

mkdir -p "$WORK_DIR/.gitnexus/post-commit.lock"
printf '999999\n' > "$WORK_DIR/.gitnexus/post-commit.lock/pid"
: > "$LOG_DIR/gitnexus.log"
PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" OBSIDIAN_VAULT="$VAULT_DIR" AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh"
grep -F "analyze --force --skip-agents-md" "$LOG_DIR/gitnexus.log" >/dev/null

echo "post-commit hook smoke test passed"
