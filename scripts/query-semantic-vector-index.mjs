#!/usr/bin/env node

import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  DEFAULT_MODEL,
  cosineSimilarity,
  createEmbeddingProvider,
  parseArgs,
} from './semantic-vector-lib.mjs';

const options = parseArgs(process.argv.slice(2));
const query = options._.join(' ').trim();
if (!query) {
  throw new Error('Usage: query-semantic-vector-index.mjs [--repo PATH] [--json] <query>');
}

const repoRoot = resolve(String(options.repo ?? process.cwd()));
const indexPath = resolve(repoRoot, String(options.index ?? 'semantic-vector-index/index.json'));
const index = JSON.parse(readFileSync(indexPath, 'utf8'));
const providerName = String(
  options.provider ??
    process.env.AGENTIC_KNOWLEDGE_VECTOR_PROVIDER ??
    index.provider?.name ??
    'gitnexus',
);
const model = String(
  options.model ??
    process.env.AGENTIC_KNOWLEDGE_VECTOR_MODEL ??
    index.provider?.model ??
    DEFAULT_MODEL,
);
const dimensions = Number.parseInt(
  String(options.dimensions ?? index.provider?.dimensions ?? '384'),
  10,
);
const device = String(options.device ?? process.env.AGENTIC_KNOWLEDGE_VECTOR_DEVICE ?? 'cpu');
const limit = Number.parseInt(String(options.limit ?? '5'), 10);

const provider = await createEmbeddingProvider({
  provider: providerName,
  model,
  dimensions,
  device,
});

try {
  const [queryVector] = await provider.embed([query]);
  const results = index.items
    .map((item) => ({
      id: item.id,
      label: item.label,
      score: cosineSimilarity(queryVector, item.embedding),
      sourceFile: item.sourceFile,
      sourceLocation: item.sourceLocation,
      text: item.text,
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);

  if (options.json) {
    console.log(
      JSON.stringify(
        {
          query,
          provider: {
            name: provider.name,
            model: provider.model,
            semantic: provider.semantic,
          },
          results,
        },
        null,
        2,
      ),
    );
  } else {
    for (const [index, result] of results.entries()) {
      const location = result.sourceLocation || result.sourceFile || 'unknown';
      console.log(`${index + 1}. ${result.label} (${result.score.toFixed(4)}) ${location}`);
    }
  }
} finally {
  await provider.dispose();
}
