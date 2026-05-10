# Agentic Knowledge Kit Agent Rules

This repository is both a software project and an Obsidian-compatible agentic
knowledge vault. Treat the project root as the vault root.

## Knowledge Layout

- `raw/`: immutable source drops. Add original documents, exports, articles,
  transcripts, PDFs, and reference material here. Do not rewrite source files
  in place.
- `wiki/`: LLM-generated synthesis derived from `raw/`, repository code, and
  graph/index outputs.
- `wiki/concepts/`: durable concept notes.
- `wiki/entities/`: people, projects, tools, systems, libraries, and named
  objects.
- `wiki/sources/`: source-specific summaries that point back to files in
  `raw/`.
- `graphify-out/`: semantic graph artifacts, including `GRAPH_REPORT.md` and
  `graph.json`.
- `.gitnexus/`: local GitNexus structural code index.

## Strict Operation Rules

1. INGEST
   - Read immutable source material from `raw/`.
   - Write synthesized notes only under `wiki/`.
   - Update backlinks and cross-references between `wiki/concepts/`,
     `wiki/entities/`, and `wiki/sources/`.
   - Preserve provenance by linking each synthesis note to its source file.

2. QUERY
   - Search an index or graph before answering project questions.
   - Prefer GitNexus for structural code questions.
   - Prefer Graphify for semantic, cross-document, or cross-modal questions.
   - Prefer Obsidian memory for prior durable project decisions and workflows.
   - If an index is missing or stale, say so and rebuild or refresh it when
     the task requires current context.

3. LINT
   - Periodically check for contradictions, stale generated notes, broken
     source links, and orphan pages.
   - Treat notes without inbound links, outbound links, or source references as
     candidates for cleanup.
   - Do not delete user-authored notes without explicit approval.

## Operational Notes

- Keep generated caches local unless a tracked artifact is explicitly required.
- `GRAPH_REPORT.md` and `graph.json` are intended to be inspectable from the
  Obsidian vault.
- GitNexus embeddings are opt-in in this environment because the native
  LadybugDB vector path has previously failed here; use non-embedding indexing
  unless the user asks otherwise.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **agentic-knowledge-kit** (416 symbols, 599 relationships, 18 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/agentic-knowledge-kit/context` | Codebase overview, check index freshness |
| `gitnexus://repo/agentic-knowledge-kit/clusters` | All functional areas |
| `gitnexus://repo/agentic-knowledge-kit/processes` | All execution flows |
| `gitnexus://repo/agentic-knowledge-kit/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |
| Work in the Scripts area (56 symbols) | `.claude/skills/generated/scripts/SKILL.md` |

<!-- gitnexus:end -->

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- For cross-module "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse the graph's EXTRACTED + INFERRED edges instead of scanning files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)

<!-- agentic-knowledge:start -->
## Agentic Knowledge Setup

This repo is wired for GitNexus, graphify, LanceDB semantic retrieval, and
Obsidian project memory.

- GitNexus MCP repo name: `agentic-knowledge-kit`
- graphify graph: `graphify-out/`
- semantic vector index: `semantic-vector-index/lancedb` and `semantic-vector-index/manifest.json`
- task context broker: `node scripts/agentic-knowledge-context.mjs "<task>"`
- LLM Wiki ingest: `node scripts/ingest-llm-wiki.mjs raw/<source>`
- LLM Wiki lint: `node scripts/lint-llm-wiki.mjs --strict`
- Obsidian project logs: `/Users/shenghongchen/Documents/Obsidian Vault/agentic-knowledge-kit/Development Logs/`
- post-commit hook: `scripts/post-commit-hook.sh`

After commits, the hook serializes GitNexus with a repo-local lock, force-rebuilds the non-embedding GitNexus index, updates graphify, rebuilds the independent LanceDB semantic vector index, and appends the monthly Obsidian commit log. GitNexus LadybugDB embeddings are opt-in via `AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS=1` because some vector-index combinations can fail in native code; if embeddings fail, the hook force-rebuilds the non-embedding index so MCP remains usable. The semantic vector index uses GitNexus bundled transformers by default and writes vectors to LanceDB outside LadybugDB.

### Retrieval Protocol

At the start of each task that needs repository context, run or consume the
task context broker before broad raw-file search:

```bash
node scripts/agentic-knowledge-context.mjs "<task summary>" --limit "${AGENTIC_KNOWLEDGE_CONTEXT_LIMIT:-5}"
```

Use the returned semantic matches as starting points only. Verify structural
questions with GitNexus, cross-module relationships with graphify, and exact
behavior in source files/tests before editing. If the semantic vector index is
missing or stale, continue with GitNexus/graphify and rebuild with
`graphify update . && node scripts/build-semantic-vector-index.mjs` when the
task depends on current context.

Claude Code receives this broker output automatically through the
`.claude/settings.json` `UserPromptSubmit` hook. Codex and Antigravity
agents must follow this protocol from `AGENTS.md`, `GEMINI.md`, and the
workspace rule files.
<!-- agentic-knowledge:end -->
