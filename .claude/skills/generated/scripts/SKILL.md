---
name: scripts
description: "Skill for the Scripts area of agentic-knowledge-kit. 56 symbols across 5 files."
---

# Scripts

56 symbols | 5 files | Cohesion: 83%

## When to Use

- Working with code in `scripts/`
- Understanding how repoRelative, sha256File, ensureWikiLayout work
- Modifying scripts-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `scripts/llm-wiki-lib.mjs` | repoRelative, sha256File, ensureWikiLayout, noteTarget, parseFrontmatter (+16) |
| `scripts/semantic-vector-lib.mjs` | sha256File, createEmbeddingProvider, openLanceDb, writeLanceTable, searchLanceTable (+11) |
| `scripts/lint-llm-wiki.mjs` | firstHeading, issue, sourceNotes, validateSourceNote, validateLinks (+4) |
| `scripts/ingest-llm-wiki.mjs` | sourceSlug, formatBulletList, upsertLinkedNote, sourceNoteBody, ingestSource |
| `scripts/agentic-knowledge-context.mjs` | unavailableJson, buildContext, compactText, resultLocation, formatContext |

## Entry Points

Start here when exploring this area:

- **`repoRelative`** (Function) — `scripts/llm-wiki-lib.mjs:96`
- **`sha256File`** (Function) — `scripts/llm-wiki-lib.mjs:107`
- **`ensureWikiLayout`** (Function) — `scripts/llm-wiki-lib.mjs:111`
- **`noteTarget`** (Function) — `scripts/llm-wiki-lib.mjs:143`
- **`parseFrontmatter`** (Function) — `scripts/llm-wiki-lib.mjs:276`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `repoRelative` | Function | `scripts/llm-wiki-lib.mjs` | 96 |
| `sha256File` | Function | `scripts/llm-wiki-lib.mjs` | 107 |
| `ensureWikiLayout` | Function | `scripts/llm-wiki-lib.mjs` | 111 |
| `noteTarget` | Function | `scripts/llm-wiki-lib.mjs` | 143 |
| `parseFrontmatter` | Function | `scripts/llm-wiki-lib.mjs` | 276 |
| `extractWikiLinks` | Function | `scripts/llm-wiki-lib.mjs` | 290 |
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
| `searchLanceTable` | Function | `scripts/semantic-vector-lib.mjs` | 315 |
| `wikilink` | Function | `scripts/llm-wiki-lib.mjs` | 138 |
| `readSourceText` | Function | `scripts/llm-wiki-lib.mjs` | 190 |
| `writeTextFile` | Function | `scripts/llm-wiki-lib.mjs` | 319 |

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
| `Lint → WalkFiles` | cross_community | 3 |
| `Lint → RepoRelative` | intra_community | 3 |
| `Lint → ParseFrontmatter` | intra_community | 3 |

## How to Explore

1. `gitnexus_context({name: "repoRelative"})` — see callers and callees
2. `gitnexus_query({query: "scripts"})` — find related execution flows
3. Read key files listed above for implementation details
