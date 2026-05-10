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
