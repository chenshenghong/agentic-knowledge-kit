# Agentic Knowledge Kit

Reusable Codex/agent skill and installer for adding a project knowledge layer to a git repository.

It wires together:

- GitNexus code intelligence and MCP configuration
- graphify semantic knowledge graph
- Obsidian project commit logs
- Codex and Claude graph-aware hook configuration
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
git diff --check
```

## Notes

GitNexus embeddings can fail in the LadybugDB vector index step on some versions/platforms. The generated hook defaults to the reliable non-embedding index and serializes GitNexus work with a repo-local lock. Set `AGENTIC_KNOWLEDGE_ENABLE_EMBEDDINGS=1` or pass `--enable-embeddings` during install to opt in to embeddings. If embeddings fail, the hook force-rebuilds without embeddings so MCP access remains usable.
