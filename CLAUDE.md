# Claude Project Rules

Follow the repository-wide agent rules in `AGENTS.md`.

Minimum operating loop:

1. INGEST: read from `raw/`, write synthesis to `wiki/`, and maintain
   cross-references.
2. QUERY: search GitNexus, Graphify, or Obsidian memory before answering
   project questions.
3. LINT: check periodically for contradictions, broken links, stale generated
   notes, and orphan pages.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **agentic-knowledge-kit** (260 symbols, 321 relationships, 6 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

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

<!-- gitnexus:end -->

<!-- agentic-knowledge:start -->
## Agentic Knowledge Setup

This repo is wired for GitNexus, graphify, LanceDB semantic retrieval, and
Obsidian project memory.

- GitNexus MCP repo name: `agentic-knowledge-kit`
- graphify graph: `graphify-out/`
- semantic vector index: `semantic-vector-index/lancedb` and `semantic-vector-index/manifest.json`
- task context broker: `node scripts/agentic-knowledge-context.mjs "<task>"`
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
