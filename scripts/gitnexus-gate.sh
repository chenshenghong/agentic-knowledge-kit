#!/usr/bin/env bash
#
# gitnexus-gate.sh — point-of-use freshness gate for GitNexus edit-safety tools.
#
# Wired as a PreToolUse hook on mcp__gitnexus__{impact,rename,detect_changes}.
# (explain/PDG taint is NOT gated here: it needs a separate `analyze --pdg` pass —
#  refresh it manually with `AGENTIC_KNOWLEDGE_PDG=1 pnpm gitnexus:fresh`.)
# GitNexus is no longer rebuilt on every commit (slow), so its index drifts. Rather
# than rely on a human/agent REMEMBERING to run `gitnexus:fresh` before a risky edit,
# this gate makes freshness a SYSTEM PROPERTY: right before one of those tools runs,
# it cheaply checks whether the index is behind HEAD and, only if so, refreshes first.
#
# Cost: ~50ms (string compare) when fresh — the common case. ~25s only when actually
# stale AND actually about to use an edit-safety tool, i.e. exactly when it's worth it.
# Self-deduping: after one refresh, lastCommit == HEAD, so back-to-back calls no-op.
#
# Always exits 0 (never blocks the tool): worst case the tool runs on a slightly stale
# index, which is no worse than before this gate existed.

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO_ROOT" ]] || exit 0
cd "$REPO_ROOT" || exit 0

META="$REPO_ROOT/.gitnexus/meta.json"
[[ -f "$META" ]] || exit 0   # not indexed yet — let the tool surface its own error

HEAD="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
LAST="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('lastCommit',''))" "$META" 2>/dev/null || echo '')"

# Fresh — fast no-op (the hot path).
[[ -n "$LAST" && "$LAST" == "$HEAD" ]] && exit 0

# Stale → refresh before the tool runs. Guard against concurrent refreshes (multiple
# agents on a shared worktree) with a pid-stamped mkdir lock + dead-pid reclaim.
LOCK="$REPO_ROOT/.gitnexus/gate-refresh.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  if [[ -f "$LOCK/pid" ]] && ! kill -0 "$(cat "$LOCK/pid" 2>/dev/null || echo -1)" 2>/dev/null; then
    rm -rf "$LOCK"; mkdir "$LOCK" 2>/dev/null || exit 0
  else
    echo "[gitnexus-gate] a refresh is already running — proceeding (results may lag one refresh)" >&2
    exit 0
  fi
fi
printf '%s\n' "$$" > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT

echo "[gitnexus-gate] index stale (${LAST:0:7} → HEAD ${HEAD:0:7}) — refreshing before edit-safety tool…" >&2
# Non-force, --skip-agents-md: up-to-date-aware, no CLAUDE.md / skill-file churn.
if command -v gitnexus >/dev/null 2>&1; then
  gitnexus analyze --skip-agents-md >/dev/null 2>&1 || echo "[gitnexus-gate] refresh failed — proceeding on existing index" >&2
elif command -v npx >/dev/null 2>&1; then
  npx gitnexus analyze --skip-agents-md >/dev/null 2>&1 || echo "[gitnexus-gate] refresh failed — proceeding on existing index" >&2
else
  echo "[gitnexus-gate] gitnexus/npx not found — proceeding on existing index" >&2
fi
exit 0
