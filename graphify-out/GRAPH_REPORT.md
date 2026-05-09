# Graph Report - agentic-knowledge-kit  (2026-05-09)

## Corpus Check
- 14 files · ~4,440 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 148 nodes · 222 edges · 17 communities (10 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `aadbbd19`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]

## God Nodes (most connected - your core abstractions)
1. `Agentic Knowledge Setup` - 8 edges
2. `createEmbeddingProvider()` - 7 edges
3. `wiki/README.md` - 7 edges
4. `parseArgs()` - 6 edges
5. `sha256File()` - 6 edges
6. `readSourceSnippet()` - 6 edges
7. `GitNexus — Code Intelligence` - 6 edges
8. `collectGraphItems()` - 5 edges
9. `writeLanceTable()` - 5 edges
10. `searchLanceTable()` - 5 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities (17 total, 7 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.09
Nodes (32): graphify, Agentic Knowledge Kit Agent Rules, Strict Operation Rules, Operational Notes, GitNexus — Code Intelligence, Always Do, Knowledge Layout, Never Do (+24 more)

### Community 1 - "Community 1"
Cohesion: 0.22
Nodes (23): buildItem(), collectGraphItems(), cosineSimilarity(), createEmbeddingProvider(), deterministicVector(), embedInBatches(), findRepoFileBySuffix(), getCurrentCommit() (+15 more)

### Community 2 - "Community 2"
Cohesion: 0.1
Nodes (21): .codex/hooks.json, .gitnexus, graphify-out, post-commit hook, QUERY, Install Into A Repository, Agentic Knowledge Kit, Use As A Skill (+13 more)

### Community 3 - "Community 3"
Cohesion: 0.15
Nodes (12): Agentic Knowledge Setup, code:bash (./scripts/install-agentic-knowledge.sh \), code:bash (bash scripts/test-post-commit-hook.sh), code:bash (test -L .git/hooks/post-commit), code:text (<vault>/<project>/Development Logs/YYYY-MM commit log.md), Installer, Known Caveat, Obsidian Memory (+4 more)

### Community 4 - "Community 4"
Cohesion: 0.18
Nodes (10): Agentic Knowledge Kit, code:bash (./scripts/install-agentic-knowledge.sh \), code:bash (./scripts/install-agentic-knowledge.sh \), code:bash (./scripts/install-agentic-knowledge.sh \), code:text (Use $agentic-knowledge-setup to add GitNexus, graphify, and ), code:bash (bash scripts/test-post-commit-hook.sh), Install Into A Repository, Notes (+2 more)

### Community 5 - "Community 5"
Cohesion: 0.18
Nodes (10): Agentic Knowledge Kit Agent Rules, Always Do, CLI, GitNexus — Code Intelligence, graphify, Knowledge Layout, Never Do, Operational Notes (+2 more)

### Community 6 - "Community 6"
Cohesion: 0.29
Nodes (6): Always Do, Claude Project Rules, CLI, GitNexus — Code Intelligence, Never Do, Resources

### Community 7 - "Community 7"
Cohesion: 0.5
Nodes (3): Current Build, Graphify Knowledge Graph, Tracked Artifacts

## Knowledge Gaps
- **70 isolated node(s):** `code:bash (./scripts/install-agentic-knowledge.sh \)`, `code:bash (./scripts/install-agentic-knowledge.sh \)`, `code:bash (./scripts/install-agentic-knowledge.sh \)`, `code:text (Use $agentic-knowledge-setup to add GitNexus, graphify, and )`, `code:bash (bash scripts/test-post-commit-hook.sh)` (+65 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `code:bash (./scripts/install-agentic-knowledge.sh \)`, `code:bash (./scripts/install-agentic-knowledge.sh \)`, `code:bash (./scripts/install-agentic-knowledge.sh \)` to the rest of the system?**
  _70 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.09 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._