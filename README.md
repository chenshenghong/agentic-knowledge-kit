# Agentic Knowledge Kit

Reusable Codex/agent skill and installer for adding a project knowledge layer to a git repository.

It wires together:

- GitNexus code intelligence and MCP configuration
- graphify semantic knowledge graph
- independent LanceDB semantic vector index
- task-start context broker for LanceDB retrieval
- LLM Wiki ingest and lint commands for `raw/` -> `wiki/` synthesis
- Obsidian project commit logs
- Codex, Claude Code, and Antigravity retrieval-aware configuration
- a post-commit hook that refreshes local knowledge artifacts

## Install Into A Repository

From this repository:

```bash
./scripts/install-agentic-knowledge.sh \
  --repo /path/to/project \
  --project-name ProjectName
```

To only write files and skip the first GitNexus/graphify run:

```bash
./scripts/install-agentic-knowledge.sh \
  --repo /path/to/project \
  --project-name ProjectName \
  --skip-initial-run
```

To opt in to GitNexus embeddings during install and in the generated post-commit hook:

```bash
./scripts/install-agentic-knowledge.sh \
  --repo /path/to/project \
  --project-name ProjectName \
  --enable-embeddings
```

## Use As A Skill

Copy this repository folder into a Codex/agent skills directory, then ask:

```text
Use $agentic-knowledge-setup to add GitNexus, graphify, and Obsidian memory hooks to this repository.
```

## Verification

After installing into a target repo:

```bash
bash scripts/test-post-commit-hook.sh
gitnexus status
graphify update .
scripts/install-vector-deps.sh
node scripts/build-semantic-vector-index.mjs
node scripts/query-semantic-vector-index.mjs "authentication flow"
node scripts/agentic-knowledge-context.mjs "authentication flow"
node scripts/ingest-llm-wiki.mjs raw/<document>
node scripts/lint-llm-wiki.mjs --strict
npm test
git diff --check
```

## Notes

GitNexus embeddings can fail in the LadybugDB vector index step on some versions/platforms. The generated hook defaults to the reliable non-embedding index and serializes GitNexus work with a repo-local lock. Set `AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS=1` or pass `--enable-embeddings` during install to opt in to LadybugDB embeddings. If embeddings fail, the hook force-rebuilds without embeddings so MCP access remains usable.

For semantic vector search, the kit builds an independent LanceDB store at `semantic-vector-index/lancedb` with metadata in `semantic-vector-index/manifest.json`. It uses GitNexus bundled transformers by default, with the same `Snowflake/snowflake-arctic-embed-xs` model, but stores vectors outside LadybugDB.

`scripts/agentic-knowledge-context.mjs` is the bridge that makes LanceDB useful
inside agent workflows. It reads a task prompt from argv or stdin, searches the
semantic vector index, and emits a compact context packet. Claude Code gets that
packet automatically through a `UserPromptSubmit` hook. Codex and Antigravity
receive durable rules in `AGENTS.md`, `GEMINI.md`, and `.agents/rules/` telling
them to run the broker before broad repository exploration.

LLM Wiki commands turn the Karpathy-style `raw/` folder into an Obsidian-ready
wiki substrate:

```bash
node scripts/ingest-llm-wiki.mjs raw/<document>
node scripts/lint-llm-wiki.mjs --strict
```

`ingest-llm-wiki.mjs` writes source summaries under `wiki/sources/`, creates or
updates linked concept notes under `wiki/concepts/`, creates or updates entity
notes under `wiki/entities/`, and preserves raw-file provenance with a SHA-256
hash. `lint-llm-wiki.mjs` checks provenance, broken wikilinks, stale raw hashes,
duplicate titles, and orphan notes.

Vector index knobs:

- `AGENTIC_KNOWLEDGE_VECTOR_INDEX=0` disables hook-time vector rebuilds.
- `AGENTIC_KNOWLEDGE_VECTOR_MODEL=Snowflake/snowflake-arctic-embed-xs` overrides the local embedding model.
- `AGENTIC_KNOWLEDGE_VECTOR_PROVIDER=test` is only for smoke tests; it is deterministic, not semantic.
- `AGENTIC_KNOWLEDGE_SKIP_VECTOR_DEPS=1` skips isolated `@lancedb/lancedb` installation under `scripts/node_modules`.
- `AGENTIC_KNOWLEDGE_CONTEXT_LIMIT=5` controls how many semantic matches are injected for each task.
