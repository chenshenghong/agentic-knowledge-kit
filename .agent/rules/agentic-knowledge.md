# Agentic Knowledge Retrieval

Before starting a repository task, query the local semantic vector index when it
exists:

```bash
node scripts/agentic-knowledge-context.mjs "<task summary>" --limit "${AGENTIC_KNOWLEDGE_CONTEXT_LIMIT:-5}"
```

Use semantic matches as a starting point, then verify with GitNexus for code
structure, graphify for cross-module relationships, and source files/tests for
exact behavior. If the index is missing or stale, continue without blocking and
rebuild with `graphify update . && node scripts/build-semantic-vector-index.mjs`
when current context matters.

For LLM Wiki ingestion, read immutable material from `raw/`, write synthesis
under `wiki/`, and run `node scripts/lint-llm-wiki.mjs --strict` before treating
wiki notes as clean.

Do not expose raw vectors or embeddings in user-facing answers.
