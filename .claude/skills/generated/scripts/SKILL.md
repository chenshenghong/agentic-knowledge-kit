---
name: scripts
description: "Skill for the Scripts area of agentic-knowledge-kit. 15 symbols across 1 files."
---

# Scripts

15 symbols | 1 files | Cohesion: 92%

## When to Use

- Working with code in `scripts/`
- Understanding how readJson, collectGraphItems, resolveInside work
- Modifying scripts-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `scripts/semantic-vector-lib.mjs` | readJson, collectGraphItems, buildItem, sha256, resolveInside (+10) |

## Entry Points

Start here when exploring this area:

- **`readJson`** (Function) — `scripts/semantic-vector-lib.mjs:52`
- **`collectGraphItems`** (Function) — `scripts/semantic-vector-lib.mjs:91`
- **`resolveInside`** (Function) — `scripts/semantic-vector-lib.mjs:83`
- **`openLanceDb`** (Function) — `scripts/semantic-vector-lib.mjs:290`
- **`writeLanceTable`** (Function) — `scripts/semantic-vector-lib.mjs:296`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `readJson` | Function | `scripts/semantic-vector-lib.mjs` | 52 |
| `collectGraphItems` | Function | `scripts/semantic-vector-lib.mjs` | 91 |
| `resolveInside` | Function | `scripts/semantic-vector-lib.mjs` | 83 |
| `openLanceDb` | Function | `scripts/semantic-vector-lib.mjs` | 290 |
| `writeLanceTable` | Function | `scripts/semantic-vector-lib.mjs` | 296 |
| `searchLanceTable` | Function | `scripts/semantic-vector-lib.mjs` | 315 |
| `createEmbeddingProvider` | Function | `scripts/semantic-vector-lib.mjs` | 209 |
| `embed` | Method | `scripts/semantic-vector-lib.mjs` | 222 |
| `buildItem` | Function | `scripts/semantic-vector-lib.mjs` | 113 |
| `sha256` | Function | `scripts/semantic-vector-lib.mjs` | 408 |
| `readSourceSnippet` | Function | `scripts/semantic-vector-lib.mjs` | 148 |
| `findRepoFileBySuffix` | Function | `scripts/semantic-vector-lib.mjs` | 177 |
| `parseLineNumber` | Function | `scripts/semantic-vector-lib.mjs` | 200 |
| `locateGitNexusEmbedder` | Function | `scripts/semantic-vector-lib.mjs` | 376 |
| `deterministicVector` | Function | `scripts/semantic-vector-lib.mjs` | 365 |

## Execution Flows

| Flow | Type | Steps |
|------|------|-------|
| `CollectGraphItems → ResolveInside` | cross_community | 4 |
| `CollectGraphItems → FindRepoFileBySuffix` | cross_community | 4 |
| `CollectGraphItems → ParseLineNumber` | cross_community | 4 |
| `CollectGraphItems → Sha256` | intra_community | 3 |

## How to Explore

1. `gitnexus_context({name: "readJson"})` — see callers and callees
2. `gitnexus_query({query: "scripts"})` — find related execution flows
3. Read key files listed above for implementation details
