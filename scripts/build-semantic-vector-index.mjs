#!/usr/bin/env node

import { resolve } from 'node:path';
import {
  DEFAULT_MODEL,
  collectGraphItems,
  createEmbeddingProvider,
  embedInBatches,
  getCurrentCommit,
  parseArgs,
  repoRelative,
  roundVector,
  writeJson,
} from './semantic-vector-lib.mjs';

const options = parseArgs(process.argv.slice(2));
const repoRoot = resolve(String(options.repo ?? process.cwd()));
const graphPath = resolve(repoRoot, String(options.graph ?? 'graphify-out/graph.json'));
const outPath = resolve(repoRoot, String(options.out ?? 'semantic-vector-index/index.json'));
const providerName = String(
  options.provider ?? process.env.AGENTIC_KNOWLEDGE_VECTOR_PROVIDER ?? 'gitnexus',
);
const model = String(options.model ?? process.env.AGENTIC_KNOWLEDGE_VECTOR_MODEL ?? DEFAULT_MODEL);
const dimensions = Number.parseInt(String(options.dimensions ?? '384'), 10);
const batchSize = Number.parseInt(String(options['batch-size'] ?? '16'), 10);
const maxTextChars = Number.parseInt(String(options['max-text-chars'] ?? '6000'), 10);
const maxItems = Number.parseInt(String(options['max-items'] ?? '0'), 10);
const device = String(options.device ?? process.env.AGENTIC_KNOWLEDGE_VECTOR_DEVICE ?? 'cpu');

const { nodes, links, items } = collectGraphItems({
  repoRoot,
  graphPath,
  maxTextChars,
  maxItems,
});

if (items.length === 0) {
  throw new Error(`No embeddable graph nodes found in ${repoRelative(repoRoot, graphPath)}`);
}

const provider = await createEmbeddingProvider({
  provider: providerName,
  model,
  dimensions,
  device,
});

try {
  const vectors = await embedInBatches(
    provider,
    items.map((item) => item.text),
    batchSize,
  );

  const output = {
    schemaVersion: 1,
    generatedAt: new Date().toISOString(),
    repo: {
      path: repoRoot,
      commit: getCurrentCommit(repoRoot),
    },
    provider: {
      name: provider.name,
      model: provider.model,
      dimensions: vectors[0]?.length ?? provider.dimensions,
      semantic: provider.semantic,
      device: provider.device ?? null,
    },
    source: {
      graphPath: repoRelative(repoRoot, graphPath),
      nodeCount: nodes.length,
      linkCount: links.length,
      indexedItemCount: items.length,
    },
    items: items.map((item, index) => ({
      ...item,
      embedding: roundVector(vectors[index]),
    })),
  };

  writeJson(outPath, output);
  console.log(
    `Semantic vector index written: ${repoRelative(repoRoot, outPath)} (${items.length} items, ${output.provider.dimensions} dims, provider=${provider.name})`,
  );
} finally {
  await provider.dispose();
}
