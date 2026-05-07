#!/usr/bin/env node

import { dirname, resolve } from 'node:path';
import {
  DEFAULT_MODEL,
  collectGraphItems,
  createEmbeddingProvider,
  embedInBatches,
  getCurrentCommit,
  parseArgs,
  repoRelative,
  roundVector,
  sha256File,
  withDirectoryLock,
  writeLanceTable,
  writeJson,
} from './semantic-vector-lib.mjs';

const options = parseArgs(process.argv.slice(2));
const repoRoot = resolve(String(options.repo ?? process.cwd()));
const graphPath = resolve(repoRoot, String(options.graph ?? 'graphify-out/graph.json'));
const requestedOut = options.out ? String(options.out) : null;
const indexDir = requestedOut?.endsWith('.json')
  ? dirname(resolve(repoRoot, requestedOut))
  : resolve(repoRoot, String(options.out ?? options.dir ?? 'semantic-vector-index'));
const dbPath = resolve(indexDir, String(options.db ?? 'lancedb'));
const manifestPath = requestedOut?.endsWith('.json')
  ? resolve(repoRoot, requestedOut)
  : resolve(indexDir, String(options.manifest ?? 'manifest.json'));
const tableName = String(options.table ?? 'nodes');
const providerName = String(
  options.provider ?? process.env.AGENTIC_KNOWLEDGE_VECTOR_PROVIDER ?? 'gitnexus',
);
const model = String(options.model ?? process.env.AGENTIC_KNOWLEDGE_VECTOR_MODEL ?? DEFAULT_MODEL);
const dimensions = Number.parseInt(String(options.dimensions ?? '384'), 10);
const batchSize = Number.parseInt(String(options['batch-size'] ?? '16'), 10);
const maxTextChars = Number.parseInt(String(options['max-text-chars'] ?? '6000'), 10);
const maxItems = Number.parseInt(String(options['max-items'] ?? '0'), 10);
const device = String(options.device ?? process.env.AGENTIC_KNOWLEDGE_VECTOR_DEVICE ?? 'cpu');
const lockTimeoutSecs = Number.parseInt(
  String(options['lock-timeout'] ?? process.env.AGENTIC_KNOWLEDGE_VECTOR_LOCK_TIMEOUT_SECS ?? '600'),
  10,
);

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

  const rows = items.map((item, index) => ({
    id: item.id,
    label: item.label,
    sourceFile: item.sourceFile ?? '',
    sourceLocation: item.sourceLocation ?? '',
    fileType: item.fileType ?? '',
    community: item.community === null || item.community === undefined ? '' : String(item.community),
    text: item.text,
    textHash: item.textHash,
    vector: roundVector(vectors[index]),
  }));

  const manifest = {
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
    store: {
      kind: 'lancedb',
      uri: repoRelative(repoRoot, dbPath),
      table: tableName,
      vectorColumn: 'vector',
      textColumn: 'text',
    },
    source: {
      graphPath: repoRelative(repoRoot, graphPath),
      graphHash: sha256File(graphPath),
      nodeCount: nodes.length,
      linkCount: links.length,
      indexedItemCount: items.length,
    },
  };

  await withDirectoryLock(
    resolve(indexDir, '.build.lock'),
    async () => {
      await writeLanceTable({ dbPath, tableName, rows });
      writeJson(manifestPath, manifest);
    },
    lockTimeoutSecs,
  );

  console.log(
    `Semantic vector index written: ${repoRelative(repoRoot, dbPath)} table=${tableName} (${items.length} items, ${manifest.provider.dimensions} dims, provider=${provider.name})`,
  );
} finally {
  await provider.dispose();
}
