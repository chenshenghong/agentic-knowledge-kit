---
name: agentic-knowledge-setup
description: Use when a repository should be wired for GitNexus, graphify, Obsidian project memory, post-commit knowledge graph updates, or cross-agent codebase context across Codex, Claude, Cursor, Gemini, and related AI tools.
---

# Agentic Knowledge Setup

## Overview

Install a repeatable agentic knowledge layer for a repo: GitNexus code intelligence, graphify semantic graph, Obsidian project commit memory, and AI-tool guidance files.

Use the bundled installer first; patch generated files only when the target repo needs local variation.

## Workflow

1. Inspect repo state: `git status --short --branch`, existing `AGENTS.md`, `CLAUDE.md`, `.mcp.json`, `.gitnexusignore`, `.git/hooks/post-commit`.
2. Pick a project name. Default to `basename "$(git rev-parse --show-toplevel)"`.
3. Run `scripts/install-agentic-knowledge.sh` from this skill directory against the target repo.
4. Run verification commands listed below.
5. If Obsidian memory MCP is available, capture the setup result and any caveats.

## Installer

From any target repo:

```bash
./scripts/install-agentic-knowledge.sh \
  --repo . \
  --project-name "$(basename "$(git rev-parse --show-toplevel)")"
```

Useful flags:

- `--vault-root "$HOME/Documents/Obsidian Vault"` writes project logs under that vault.
- `--obsidian-project-dir /path/to/vault/Project` writes directly to a project folder.
- `--skip-initial-run` installs files/hooks without running GitNexus or graphify.
- `--enable-embeddings` opts in to GitNexus embeddings during install and in the generated hook.
- `--skip-vector-deps` skips isolated LanceDB dependency installation under `scripts/node_modules`.
- `--no-claude`, `--no-codex`, `--no-gitnexus-skills` for narrower installs.

## What It Installs

- Repo scripts: `scripts/post-commit-hook.sh`, `scripts/install-knowledge-hook.sh`, `scripts/test-post-commit-hook.sh`, `scripts/install-vector-deps.sh`, `scripts/build-semantic-vector-index.mjs`, `scripts/query-semantic-vector-index.mjs`.
- Git hook: `.git/hooks/post-commit` symlink to the repo script.
- Agent config: `AGENTS.md`, `CLAUDE.md`, `.mcp.json`, `.gitnexusignore`, `.codex/hooks.json`, `.claude/settings.json`.
- Local generated artifacts: `.gitnexus/`, `graphify-out/`, `semantic-vector-index/`, `scripts/node_modules/`, `.claude/skills/...`.

The installer updates `.gitignore` so `.gitnexus/`, `graphify-out/`, `semantic-vector-index/`, and `scripts/node_modules/` stay local, while `.claude/skills/...` can be tracked.

## Verification

Run:

```bash
bash scripts/test-post-commit-hook.sh
gitnexus status
graphify update .
scripts/install-vector-deps.sh
node scripts/build-semantic-vector-index.mjs
node scripts/query-semantic-vector-index.mjs "recording transcription flow"
graphify query "recording transcription flow" --budget 800
git diff --check
```

Also confirm:

```bash
test -L .git/hooks/post-commit
test -f graphify-out/graph.json
test -d semantic-vector-index/lancedb
test -f semantic-vector-index/manifest.json
test -f .gitnexus/meta.json
```

For multi-repo GitNexus registries, pass `repo` explicitly in MCP calls.

## Known Caveat

GitNexus `--embeddings` can fail in the LadybugDB vector-index step on some versions/platforms. The generated post-commit hook defaults to the reliable non-embedding index, serializes GitNexus with a repo-local lock, and only attempts LadybugDB embeddings when `AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS=1` or `--enable-embeddings` was used during install. If embeddings fail, it force-rebuilds without embeddings so MCP remains usable. Semantic vector search is handled separately by LanceDB under `semantic-vector-index/lancedb`, with metadata in `semantic-vector-index/manifest.json`; it uses GitNexus bundled transformers by default and stores vectors outside LadybugDB. Mention this caveat in the final report if LadybugDB embeddings stay at `0` in `~/.gitnexus/registry.json`.

Vector index environment knobs: `AGENTIC_KNOWLEDGE_VECTOR_INDEX=0` disables hook rebuilds, `AGENTIC_KNOWLEDGE_VECTOR_MODEL=...` overrides the embedding model, `AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test` is only for deterministic smoke tests, and `AGENTIC_KNOWLEDGE_SKIP_VECTOR_DEPS=1` skips isolated LanceDB dependency installation.

## Obsidian Memory

The hook writes monthly commit logs to:

```text
<vault>/<project>/Development Logs/YYYY-MM commit log.md
```

At the end of setup, use the Obsidian memory MCP `capture_memory` when available. Store durable facts: project name, installed files, index stats, graphify stats, hook path, and any GitNexus embedding failures.
