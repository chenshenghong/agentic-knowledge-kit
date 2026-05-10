# Graph Report - agentic-knowledge-kit  (2026-05-10)

## Corpus Check
- 21 files · ~8,663 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 283 nodes · 431 edges · 23 communities (16 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c5b167fa`
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
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]

## God Nodes (most connected - your core abstractions)
1. `ingestSource()` - 10 edges
2. `createEmbeddingProvider()` - 9 edges
3. `Agentic Knowledge Setup` - 9 edges
4. `sha256File()` - 8 edges
5. `lint()` - 8 edges
6. `parseArgs()` - 7 edges
7. `searchLanceTable()` - 7 edges
8. `GitNexus — Code Intelligence` - 7 edges
9. `wiki/README.md` - 7 edges
10. `readSourceSnippet()` - 6 edges

## Surprising Connections (you probably didn't know these)
- `buildContext()` --calls--> `sha256File()`  [EXTRACTED]
  scripts/agentic-knowledge-context.mjs → scripts/semantic-vector-lib.mjs
- `buildContext()` --calls--> `createEmbeddingProvider()`  [EXTRACTED]
  scripts/agentic-knowledge-context.mjs → scripts/semantic-vector-lib.mjs
- `buildContext()` --calls--> `searchLanceTable()`  [EXTRACTED]
  scripts/agentic-knowledge-context.mjs → scripts/semantic-vector-lib.mjs
- `sourceNotes()` --calls--> `walkFiles()`  [EXTRACTED]
  scripts/lint-llm-wiki.mjs → scripts/llm-wiki-lib.mjs
- `wikiNotes()` --calls--> `walkFiles()`  [EXTRACTED]
  scripts/lint-llm-wiki.mjs → scripts/llm-wiki-lib.mjs

## Communities (23 total, 7 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (53): graphify, Agentic Knowledge Kit Agent Rules, Strict Operation Rules, Operational Notes, GitNexus — Code Intelligence, Always Do, Knowledge Layout, Never Do (+45 more)

### Community 1 - "Community 1"
Cohesion: 0.1
Nodes (42): buildContext(), batchSize, dbPath, device, dimensions, graphPath, lockTimeoutSecs, manifest (+34 more)

### Community 2 - "Community 2"
Cohesion: 0.15
Nodes (28): formatBulletList(), ingested, ingestSource(), options, repoRoot, sourceNoteBody(), sources, sourceSlug() (+20 more)

### Community 3 - "Community 3"
Cohesion: 0.21
Nodes (18): firstHeading(), issue(), lint(), options, repoRoot, report, sourceNotes(), validateDuplicateTitles() (+10 more)

### Community 4 - "Community 4"
Cohesion: 0.12
Nodes (16): currentGraphHash, dbPath, device, dimensions, graphPath, index, limit, manifestPath (+8 more)

### Community 5 - "Community 5"
Cohesion: 0.14
Nodes (14): Agentic Knowledge Setup, code:bash (./scripts/install-agentic-knowledge.sh \), code:bash (bash scripts/test-post-commit-hook.sh), code:bash (test -L .git/hooks/post-commit), code:bash (node scripts/ingest-llm-wiki.mjs raw/<document>), code:text (<vault>/<project>/Development Logs/YYYY-MM commit log.md), Installer, Known Caveat (+6 more)

### Community 6 - "Community 6"
Cohesion: 0.14
Nodes (13): Agentic Knowledge Kit Agent Rules, Agentic Knowledge Setup, Always Do, CLI, code:bash (node scripts/agentic-knowledge-context.mjs "<task summary>" ), GitNexus — Code Intelligence, graphify, Knowledge Layout (+5 more)

### Community 7 - "Community 7"
Cohesion: 0.17
Nodes (11): conceptNote, entityNote, ingestOut, installer, lint, lintJson, repoRoot, sourceNote (+3 more)

### Community 8 - "Community 8"
Cohesion: 0.17
Nodes (11): Agentic Knowledge Kit, code:bash (./scripts/install-agentic-knowledge.sh \), code:bash (./scripts/install-agentic-knowledge.sh \), code:bash (./scripts/install-agentic-knowledge.sh \), code:text (Use $agentic-knowledge-setup to add GitNexus, graphify, and ), code:bash (bash scripts/test-post-commit-hook.sh), code:bash (node scripts/ingest-llm-wiki.mjs raw/<document>), Install Into A Repository (+3 more)

### Community 9 - "Community 9"
Cohesion: 0.24
Nodes (7): compactText(), formatContext(), maxChars, options, output, resultLocation(), unavailableJson()

### Community 10 - "Community 10"
Cohesion: 0.2
Nodes (9): Agentic Knowledge Setup, Always Do, Claude Project Rules, CLI, code:bash (node scripts/agentic-knowledge-context.mjs "<task summary>" ), GitNexus — Code Intelligence, Never Do, Resources (+1 more)

### Community 11 - "Community 11"
Cohesion: 0.25
Nodes (7): buildOut, index, manifestPath, query, queryOut, repoRoot, tmp

### Community 12 - "Community 12"
Cohesion: 0.25
Nodes (7): hookContext, installer, jsonContext, missingIndex, payload, repoRoot, tmp

### Community 13 - "Community 13"
Cohesion: 0.5
Nodes (3): Agentic Knowledge Setup, code:bash (node scripts/agentic-knowledge-context.mjs "<task summary>" ), Retrieval Protocol

### Community 14 - "Community 14"
Cohesion: 0.5
Nodes (3): Current Build, Graphify Knowledge Graph, Tracked Artifacts

## Knowledge Gaps
- **145 isolated node(s):** `require`, `repoFileCache`, `repoRoot`, `tmp`, `buildOut` (+140 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `createEmbeddingProvider()` connect `Community 1` to `Community 9`, `Community 4`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Why does `sha256File()` connect `Community 1` to `Community 9`, `Community 4`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **Why does `parseArgs()` connect `Community 1` to `Community 9`, `Community 4`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **What connects `require`, `repoFileCache`, `repoRoot` to the rest of the system?**
  _145 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `Community 4` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._