#!/usr/bin/env bash
#
# Smoke test for the post-commit hook (2026-06 CMM redesign).
# The hook now: (1) runs the CMM code engine incrementally, (2) updates graphify,
# (3) rebuilds the LanceDB vector index docs-only + Obsidian, (4) writes the
# Obsidian commit log. GitNexus is NO LONGER in the hot path.

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
# Project name is pinned (not the random mktemp basename) so the Obsidian vault
# path is deterministic regardless of which repo this test is bundled into.
PNAME="hooktest"

mkdir -p "$WORK_DIR/scripts" "$BIN_DIR" "$LOG_DIR" "$VAULT_DIR"
cp "$SCRIPT_UNDER_TEST" "$WORK_DIR/scripts/post-commit-hook.sh"
cp "$REPO_ROOT/scripts/semantic-vector-lib.mjs" "$WORK_DIR/scripts/semantic-vector-lib.mjs"
cp "$REPO_ROOT/scripts/build-semantic-vector-index.mjs" "$WORK_DIR/scripts/build-semantic-vector-index.mjs"
cp "$REPO_ROOT/scripts/query-semantic-vector-index.mjs" "$WORK_DIR/scripts/query-semantic-vector-index.mjs"
cp "$REPO_ROOT/scripts/agentic-knowledge-context.mjs" "$WORK_DIR/scripts/agentic-knowledge-context.mjs"
cp "$REPO_ROOT/scripts/install-vector-deps.sh" "$WORK_DIR/scripts/install-vector-deps.sh"
chmod +x "$WORK_DIR/scripts/install-vector-deps.sh"

# CMM code-engine stub — logs invocations so we can assert the hook calls it.
cat > "$BIN_DIR/codebase-memory-mcp" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG_DIR/cmm.log"
STUB

# GitNexus stub — present on PATH but the hook must NEVER call it now.
cat > "$BIN_DIR/gitnexus" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG_DIR/gitnexus.log"
STUB

cat > "$BIN_DIR/graphify" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG_DIR/graphify.log"
STUB

chmod +x "$BIN_DIR/codebase-memory-mcp" "$BIN_DIR/gitnexus" "$BIN_DIR/graphify"

cd "$WORK_DIR"
git init -q
git config user.email "hook-test@example.com"
git config user.name "Hook Test"
echo "hook test" > README.md
mkdir -p docs graphify-out
cat > docs/guide.md <<'MD'
# Virtual Audio Guide
mixVirtualAudio combines system audio and microphone into one stream.
MD
# graph.json carries a DOCUMENT node (kept by docs-only) and a CODE node (dropped
# by docs-only — code recall is CMM's job, not the vector index's).
cat > graphify-out/graph.json <<'JSON'
{
  "directed": true,
  "graph": {},
  "nodes": [
    {
      "id": "guide_md",
      "label": "docs/guide.md",
      "source_file": "docs/guide.md",
      "source_location": "L1",
      "community": 1,
      "file_type": "document"
    },
    {
      "id": "mixVirtualAudio",
      "label": "mixVirtualAudio",
      "source_file": "src/audio.js",
      "source_location": "src/audio.js:1",
      "community": 1,
      "file_type": "code"
    }
  ],
  "links": []
}
JSON
# Obsidian vault note — the broker now ingests the vault (it lives outside repo).
mkdir -p "$VAULT_DIR/$PNAME"
cat > "$VAULT_DIR/$PNAME/note.md" <<'MD'
# Audio sync decision
Virtual audio mixer uses PTS anchoring to keep boxes in phase.
MD
git add README.md docs/guide.md
git commit -q -m "Hook test commit"
"$WORK_DIR/scripts/install-vector-deps.sh" >/dev/null

run_hook() {
  # extra "NAME=value" args (e.g. AGENTIC_KNOWLEDGE_CMM_INDEX=0) go through env,
  # which recognises them as assignments even when they come from expansion.
  env "$@" PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" OBSIDIAN_VAULT="$VAULT_DIR" \
    AGENTIC_KNOWLEDGE_PROJECT_NAME="$PNAME" \
    AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 \
    AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
    "$WORK_DIR/scripts/post-commit-hook.sh"
}

run_hook

# (1) CMM code engine invoked incrementally
grep -F "cli index_repository" "$LOG_DIR/cmm.log" >/dev/null || {
  echo "expected the hook to call CMM 'cli index_repository'" >&2; exit 1; }

# (2) GitNexus must NOT run in the commit hot path anymore
if [[ -f "$LOG_DIR/gitnexus.log" ]]; then
  echo "GitNexus must not run in the post-commit hook (it is on-demand now)" >&2; exit 1
fi

# (3) graphify updated
grep -F "update ." "$LOG_DIR/graphify.log" >/dev/null

# (4) docs-only + Obsidian vector index built
test -f "$WORK_DIR/semantic-vector-index/manifest.json"
test -d "$WORK_DIR/semantic-vector-index/lancedb"
node -e 'const fs=require("fs"); const idx=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); if (idx.provider.name !== "test" || idx.store.kind !== "lancedb" || idx.source.docsOnly !== true || idx.source.indexedItemCount < 1) process.exit(1);' "$WORK_DIR/semantic-vector-index/manifest.json"
# Obsidian vault section embedded
node -e 'const fs=require("fs"); const idx=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); if (!idx.source.obsidian || idx.source.obsidian.itemCount < 1) process.exit(1);' "$WORK_DIR/semantic-vector-index/manifest.json"

# (5) broker retrieval works
CONTEXT_OUT="$(AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test node "$WORK_DIR/scripts/agentic-knowledge-context.mjs" --repo "$WORK_DIR" --provider test "virtual audio mixer")"
grep -F "Agentic Knowledge Context" <<< "$CONTEXT_OUT" >/dev/null

# (6) Obsidian commit log written, idempotently
MONTH_TAG="$(date +'%Y-%m')"
OBSIDIAN_LOG="$VAULT_DIR/$PNAME/Development Logs/${MONTH_TAG} commit log.md"
grep -F "Hook test commit" "$OBSIDIAN_LOG" >/dev/null
grep -E -- '- `[0-9a-f]{7,}` \([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\) - Hook test commit' "$OBSIDIAN_LOG" >/dev/null

run_hook
COUNT="$(grep -c "Hook test commit" "$OBSIDIAN_LOG")"
if [[ "$COUNT" != "1" ]]; then
  echo "expected one Obsidian log entry, got $COUNT" >&2
  exit 1
fi

# (7) CMM disable toggle honored
: > "$LOG_DIR/cmm.log"
run_hook AGENTIC_KNOWLEDGE_CMM_INDEX=0
if [[ -s "$LOG_DIR/cmm.log" ]]; then
  echo "CMM should be skipped when AGENTIC_KNOWLEDGE_CMM_INDEX=0" >&2
  exit 1
fi

# Linked worktree fixture for (8)/(9).
WT_DIR="$TMP_DIR/feature-wt"
git -C "$WORK_DIR" worktree add -q -b wt-test "$WT_DIR"
echo "from worktree" >> "$WT_DIR/README.md"
git -C "$WT_DIR" commit -q -am "Worktree commit"

# (9) Explicit AGENTIC_KNOWLEDGE_PROJECT_NAME still wins inside a worktree
(cd "$WT_DIR" && env PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" OBSIDIAN_VAULT="$VAULT_DIR" \
  AGENTIC_KNOWLEDGE_PROJECT_NAME=override-name \
  AGENTIC_KNOWLEDGE_VECTOR_INDEX=0 AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 \
  AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
  "$WORK_DIR/scripts/post-commit-hook.sh" >/dev/null)
grep -F "Worktree commit" "$VAULT_DIR/override-name/Development Logs/${MONTH_TAG} commit log.md" >/dev/null || {
  echo "AGENTIC_KNOWLEDGE_PROJECT_NAME must override the derived name" >&2; exit 1; }

# (8) and (10) apply to the kit's unbaked hook (the kit ships the installer, so a
# missing token there is a failure, not a skip). Installed copies have
# --project-name baked in (a constant, so worktree-safe by construction).
if [[ -f "$REPO_ROOT/scripts/install-agentic-knowledge.sh" ]] \
  || grep -qF '$(default_project_name)' "$SCRIPT_UNDER_TEST"; then
  # (8) Linked worktree: with no explicit project name, the commit log must land in
  # the MAIN repo's vault folder (basename of WORK_DIR = "work"), not the worktree's.
  (cd "$WT_DIR" && env -u AGENTIC_KNOWLEDGE_PROJECT_NAME \
    PATH="$BIN_DIR:$PATH" STUB_LOG_DIR="$LOG_DIR" OBSIDIAN_VAULT="$VAULT_DIR" \
    AGENTIC_KNOWLEDGE_VECTOR_INDEX=0 AGENTIC_KNOWLEDGE_HOOK_ASYNC=0 \
    AGENTIC_KNOWLEDGE_HOOK_LOG_DIR="$LOG_DIR" \
    "$WORK_DIR/scripts/post-commit-hook.sh" >/dev/null)
  grep -F "Worktree commit" "$VAULT_DIR/work/Development Logs/${MONTH_TAG} commit log.md" >/dev/null || {
    echo "worktree commit should be logged under the main repo name (vault/work)" >&2; exit 1; }
  if [[ -e "$VAULT_DIR/feature-wt" ]]; then
    echo "worktree commit leaked into a stray vault folder named after the worktree" >&2; exit 1
  fi

  # (10) Generator contract: the installer bakes --project-name by replacing this
  # exact token; if it drifts, replace_token silently no-ops.
  if [[ "$(grep -cF '$(default_project_name)' "$SCRIPT_UNDER_TEST")" != "1" ]]; then
    echo "post-commit-hook.sh must contain the \$(default_project_name) token exactly once" >&2; exit 1
  fi
  if [[ -f "$REPO_ROOT/scripts/install-agentic-knowledge.sh" ]]; then
    grep -F "replace_token scripts/post-commit-hook.sh '\$(default_project_name)'" \
      "$REPO_ROOT/scripts/install-agentic-knowledge.sh" >/dev/null || {
      echo "installer replace_token must target the \$(default_project_name) token" >&2; exit 1; }
  fi
else
  echo "[test] hook has a baked project name; skipping worktree-derivation checks"
fi

echo "post-commit hook smoke test passed"
