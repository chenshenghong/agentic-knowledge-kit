---
name: scripts
description: "Skill for the Scripts area of agentic-knowledge-kit. 56 symbols across 5 files."
---

# Scripts

56 symbols | 5 files | Cohesion: 81%

## When to Use

- Working with code in `scripts/`
- Understanding how resolveInside, ensureWikiLayout, walkFiles work
- Modifying scripts-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `scripts/llm-wiki-lib.mjs` | resolveInside, ensureWikiLayout, walkFiles, expandSourceInputs, extractWikiLinks (+16) |
| `scripts/semantic-vector-lib.mjs` | sha256File, createEmbeddingProvider, openLanceDb, writeLanceTable, searchLanceTable (+11) |
| `scripts/lint-llm-wiki.mjs` | sourceNotes, wikiNotes, validateLinks, lint, firstHeading (+4) |
| `scripts/ingest-llm-wiki.mjs` | sourceSlug, formatBulletList, upsertLinkedNote, sourceNoteBody, ingestSource |
| `scripts/agentic-knowledge-context.mjs` | unavailableJson, buildContext, compactText, resultLocation, formatContext |

## Entry Points

Start here when exploring this area:

- **`resolveInside`** (Function) — `scripts/llm-wiki-lib.mjs:100`
- **`ensureWikiLayout`** (Function) — `scripts/llm-wiki-lib.mjs:111`
- **`walkFiles`** (Function) — `scripts/llm-wiki-lib.mjs:147`
- **`expandSourceInputs`** (Function) — `scripts/llm-wiki-lib.mjs:162`
- **`extractWikiLinks`** (Function) — `scripts/llm-wiki-lib.mjs:290`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `resolveInside` | Function | `scripts/llm-wiki-lib.mjs` | 100 |
| `ensureWikiLayout` | Function | `scripts/llm-wiki-lib.mjs` | 111 |
| `walkFiles` | Function | `scripts/llm-wiki-lib.mjs` | 147 |
| `expandSourceInputs` | Function | `scripts/llm-wiki-lib.mjs` | 162 |
| `extractWikiLinks` | Function | `scripts/llm-wiki-lib.mjs` | 290 |
| `resolveWikiTarget` | Function | `scripts/llm-wiki-lib.mjs` | 300 |
| `repoRelative` | Function | `scripts/llm-wiki-lib.mjs` | 96 |
| `sha256File` | Function | `scripts/llm-wiki-lib.mjs` | 107 |
| `noteTarget` | Function | `scripts/llm-wiki-lib.mjs` | 143 |
| `parseFrontmatter` | Function | `scripts/llm-wiki-lib.mjs` | 276 |
| `slugify` | Function | `scripts/llm-wiki-lib.mjs` | 117 |
| `titleFromSlug` | Function | `scripts/llm-wiki-lib.mjs` | 127 |
| `extractTitle` | Function | `scripts/llm-wiki-lib.mjs` | 199 |
| `summarizeSource` | Function | `scripts/llm-wiki-lib.mjs` | 216 |
| `extractConcepts` | Function | `scripts/llm-wiki-lib.mjs` | 243 |
| `extractEntities` | Function | `scripts/llm-wiki-lib.mjs` | 260 |
| `sha256File` | Function | `scripts/semantic-vector-lib.mjs` | 56 |
| `createEmbeddingProvider` | Function | `scripts/semantic-vector-lib.mjs` | 209 |
| `openLanceDb` | Function | `scripts/semantic-vector-lib.mjs` | 290 |
| `writeLanceTable` | Function | `scripts/semantic-vector-lib.mjs` | 296 |

## Execution Flows

| Flow | Type | Steps |
|------|------|-------|
| `CollectGraphItems → ResolveInside` | cross_community | 4 |
| `CollectGraphItems → FindRepoFileBySuffix` | cross_community | 4 |
| `CollectGraphItems → ParseLineNumber` | cross_community | 4 |
| `IngestSource → RepoRelative` | cross_community | 3 |
| `IngestSource → Slugify` | cross_community | 3 |
| `IngestSource → TitleFromSlug` | cross_community | 3 |
| `ExtractConcepts → Slugify` | intra_community | 3 |
| `Lint → WalkFiles` | intra_community | 3 |
| `Lint → RepoRelative` | cross_community | 3 |
| `Lint → ParseFrontmatter` | cross_community | 3 |

## How to Explore

1. `gitnexus_context({name: "resolveInside"})` — see callers and callees
2. `gitnexus_query({query: "scripts"})` — find related execution flows
3. Read key files listed above for implementation details
