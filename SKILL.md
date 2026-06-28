---
name: agentic-knowledge-setup
description: Use when a repository should be wired for GitNexus, graphify, Obsidian project memory, post-commit knowledge graph updates, or cross-agent codebase context across Codex, Claude, Cursor, Gemini, and related AI tools.
---

# Agentic Knowledge Setup

## Overview

Install a repeatable agentic knowledge layer for a repo: LLM Wiki ingest/lint, GitNexus code intelligence, graphify semantic graph, LanceDB semantic retrieval, Obsidian project commit memory, and AI-tool guidance files.

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
- `--skip-initial-run` installs files/hooks without running the initial index.
- `--enable-embeddings` opts in to GitNexus embeddings during the initial index (GitNexus is no longer in the post-commit hook).
- `--skip-vector-deps` skips isolated LanceDB dependency installation under `scripts/node_modules`.
- `--no-claude`, `--no-codex`, `--no-antigravity`, `--no-gitnexus-skills` for narrower installs.

## What It Installs

- Repo scripts: `scripts/post-commit-hook.sh`, `scripts/install-knowledge-hook.sh`, `scripts/test-post-commit-hook.sh`, `scripts/install-vector-deps.sh`, `scripts/build-semantic-vector-index.mjs`, `scripts/query-semantic-vector-index.mjs`, `scripts/agentic-knowledge-context.mjs`, `scripts/ingest-llm-wiki.mjs`, `scripts/lint-llm-wiki.mjs`.
- Git hook: `.git/hooks/post-commit` symlink to the repo script.
- Agent config: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.mcp.json`, `.gitnexusignore`, `.codex/hooks.json`, `.claude/settings.json`, `.agents/rules/agentic-knowledge.md`, `.agent/rules/agentic-knowledge.md`.
- LLM Wiki substrate: `raw/`, `wiki/`, `wiki/concepts/`, `wiki/entities/`, `wiki/sources/`.
- Local generated artifacts: `.gitnexus/`, `graphify-out/`, `semantic-vector-index/`, `scripts/node_modules/`, `.claude/skills/...`.

The installer updates `.gitignore` so `.gitnexus/`, `graphify-out/`, `semantic-vector-index/`, and `scripts/node_modules/` stay local, while `.claude/skills/...` can be tracked.

## Verification

Run:

```bash
bash scripts/test-post-commit-hook.sh
gitnexus status
graphify update .
scripts/install-vector-deps.sh
node scripts/build-semantic-vector-index.mjs --docs-only --obsidian
node scripts/query-semantic-vector-index.mjs "recording transcription flow"
node scripts/agentic-knowledge-context.mjs "recording transcription flow"
node scripts/ingest-llm-wiki.mjs raw/<document>
node scripts/lint-llm-wiki.mjs --strict
node scripts/test-agentic-knowledge-context.mjs
node scripts/test-llm-wiki-workflow.mjs
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

The generated post-commit hook (2026-06 CMM redesign) runs: (1) the **codebase-memory-mcp (CMM)** code engine incrementally (~0.5s, self-contained binary, no native crashes), (2) `graphify update .`, (3) the LanceDB vector index **docs-only + Obsidian vault** (`--docs-only --obsidian`; code recall is served by CMM), (4) the Obsidian commit log. **GitNexus is NOT in the hook** — it is refreshed on-demand via `scripts/gitnexus-fresh.sh` before risky edits/rename/PR review, because it is the slowest step and its LadybugDB `--embeddings` can fail on some versions/platforms. The vector index uses GitNexus's bundled transformer to embed (multilingual). Per machine, run `scripts/install-cmm.sh` once to install the CMM binary + register the MCP server; per repo, `.cbmignore` excludes vendored/build noise. If GitNexus embeddings stay at `0` in `~/.gitnexus/registry.json`, that only affects the on-demand GitNexus path, not the hook.

Vector index environment knobs: `AGENTIC_KNOWLEDGE_VECTOR_INDEX=0` disables hook rebuilds, `AGENTIC_KNOWLEDGE_VECTOR_MODEL=...` overrides the embedding model, `AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test` is only for deterministic smoke tests, and `AGENTIC_KNOWLEDGE_SKIP_VECTOR_DEPS=1` skips isolated LanceDB dependency installation. `AGENTIC_KNOWLEDGE_CONTEXT_LIMIT=5` controls how many semantic matches are injected into task-start context.

The installer makes LanceDB part of the agent workflow, not only a synchronized
artifact:

- Claude Code: `.claude/settings.json` adds a `UserPromptSubmit` hook that runs
  `scripts/agentic-knowledge-context.mjs` and injects its stdout as context.
- Codex: `AGENTS.md` instructs agents to run the context broker before broad
  raw-file search.
- Antigravity: `GEMINI.md`, `.agents/rules/agentic-knowledge.md`, and
  `.agent/rules/agentic-knowledge.md` instruct agents to use the broker at task
  start while still verifying with GitNexus, graphify, and source files.

## LLM Wiki

Use `raw/` as the immutable source drop and `wiki/` as the synthesized
Obsidian-readable knowledge layer.

```bash
node scripts/ingest-llm-wiki.mjs raw/<document>
node scripts/lint-llm-wiki.mjs --strict
```

The ingest command writes source summaries to `wiki/sources/`, creates linked
concept notes in `wiki/concepts/`, creates linked entity notes in
`wiki/entities/`, and records raw-file provenance with `source` and
`source_sha256` frontmatter. The lint command checks missing provenance, broken
wikilinks, stale raw hashes, duplicate titles, and orphan pages.

## Obsidian Memory

The hook writes monthly commit logs to:

```text
<vault>/<project>/Development Logs/YYYY-MM commit log.md
```

At the end of setup, use the Obsidian memory MCP `capture_memory` when available. Store durable facts: project name, installed files, index stats, graphify stats, hook path, and any GitNexus embedding failures.
