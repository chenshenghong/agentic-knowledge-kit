#!/usr/bin/env bash
#
# gitnexus-fresh.sh — On-demand GitNexus refresh.
#
# GitNexus is NO LONGER rebuilt on every commit (it is the slowest step and its
# embeddings can crash in native code). It is kept ONLY for the edit-safety
# primitives that nothing else provides and CLAUDE.md 鐵律 mandate:
#   - impact   (blast radius + risk grading)
#   - explain  (PDG taint: source→sink)   [needs --pdg]
#   - rename   (call-graph-aware multi-file rename)
#   - detect_changes (vs base ref)
#
# Run this BEFORE a risky edit / rename / PR review so those reflect current code.
#
# Env:
#   AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS=1   also rebuild GitNexus embeddings (opt-in; can crash)
#   AGENTIC_KNOWLEDGE_PDG=1                  also run the PDG pass (enables explain/taint; slower)

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO_ROOT" ]] || { echo "[gitnexus-fresh] not in a git repo" >&2; exit 1; }
cd "$REPO_ROOT" || exit 1

ENABLE_EMBEDDINGS="${AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS:-0}"
ENABLE_PDG="${AGENTIC_KNOWLEDGE_PDG:-0}"

# Use the SAME gitnexus version as the MCP server (.mcp.json) so the rebuilt index is
# in a storage format the MCP can read (avoids the CLI-vs-MCP storage-version skew).
GX_VER="$(python3 -c "import json;a=json.load(open('.mcp.json'))['mcpServers'].get('gitnexus',{}).get('args',[]);print(next((x.split('@',1)[1] for x in a if isinstance(x,str) and x.startswith('gitnexus@')),''))" 2>/dev/null || true)"

gx() {
  if command -v npx >/dev/null 2>&1; then
    npx -y "gitnexus${GX_VER:+@$GX_VER}" "$@"
  elif command -v gitnexus >/dev/null 2>&1; then
    gitnexus "$@"
  else
    echo "[gitnexus-fresh] npx/gitnexus not found" >&2
    return 1
  fi
}

if [[ ! -d .gitnexus ]]; then
  echo "[gitnexus-fresh] .gitnexus not initialized — run 'npx gitnexus analyze' once first" >&2
  exit 1
fi

PDG_FLAG=""
if [[ "$ENABLE_PDG" == "1" || "$ENABLE_PDG" == "true" ]]; then
  PDG_FLAG="--pdg"
fi

echo "[gitnexus-fresh] analyzing (force${PDG_FLAG:+, pdg})…"
if ! gx analyze --force --skip-agents-md $PDG_FLAG; then
  echo "[gitnexus-fresh] analyze failed" >&2
  exit 1
fi

if [[ "$ENABLE_EMBEDDINGS" == "1" || "$ENABLE_EMBEDDINGS" == "true" ]]; then
  echo "[gitnexus-fresh] rebuilding embeddings (opt-in)…"
  gx analyze --embeddings --force --skip-agents-md \
    || echo "[gitnexus-fresh] embeddings failed; non-embedding index kept (MCP still usable)" >&2
fi

echo "[gitnexus-fresh] done — impact / explain / rename / detect_changes now current"
