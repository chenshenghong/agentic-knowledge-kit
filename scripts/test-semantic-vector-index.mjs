#!/usr/bin/env node

import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { execFileSync } from 'node:child_process';

const repoRoot = resolve(new URL('..', import.meta.url).pathname);
const tmp = mkdtempSync(join(tmpdir(), 'agentic-vector-test-'));

mkdirSync(join(tmp, 'graphify-out'), { recursive: true });
mkdirSync(join(tmp, 'src'), { recursive: true });

writeFileSync(
  join(tmp, 'src', 'audio.js'),
  [
    'export function mixVirtualAudio(systemAudio, microphone) {',
    '  return [systemAudio, microphone].filter(Boolean).join(" + ");',
    '}',
    '',
  ].join('\n'),
);

writeFileSync(
  join(tmp, 'graphify-out', 'graph.json'),
  JSON.stringify(
    {
      directed: true,
      graph: {},
      nodes: [
        {
          id: 'mixVirtualAudio',
          label: 'mixVirtualAudio',
          source_file: 'src/audio.js',
          source_location: 'src/audio.js:1',
          community: 1,
          file_type: 'javascript',
        },
        {
          id: 'virtualMicrophoneOutput',
          label: 'virtualMicrophoneOutput',
          source_file: 'src/audio.js',
          source_location: 'src/audio.js:2',
          community: 1,
          file_type: 'javascript',
        },
      ],
      links: [{ source: 'mixVirtualAudio', target: 'virtualMicrophoneOutput' }],
    },
    null,
    2,
  ),
);

const buildOut = execFileSync(
  'node',
  [
    join(repoRoot, 'scripts', 'build-semantic-vector-index.mjs'),
    '--repo',
    tmp,
    '--provider',
    'test',
    '--dimensions',
    '12',
  ],
  { encoding: 'utf8' },
);

assert.match(buildOut, /Semantic vector index written/);

const indexPath = join(tmp, 'semantic-vector-index', 'index.json');
const index = JSON.parse(readFileSync(indexPath, 'utf8'));

assert.equal(index.schemaVersion, 1);
assert.equal(index.provider.name, 'test');
assert.equal(index.provider.semantic, false);
assert.equal(index.provider.dimensions, 12);
assert.equal(index.source.graphPath, 'graphify-out/graph.json');
assert.equal(index.source.nodeCount, 2);
assert.equal(index.items.length, 2);
assert.equal(index.items[0].embedding.length, 12);
assert.match(index.items[0].text, /mixVirtualAudio/);
assert.match(index.items[0].text, /systemAudio/);

const queryOut = execFileSync(
  'node',
  [
    join(repoRoot, 'scripts', 'query-semantic-vector-index.mjs'),
    '--repo',
    tmp,
    '--provider',
    'test',
    '--json',
    'virtual microphone mixer',
  ],
  { encoding: 'utf8' },
);

const query = JSON.parse(queryOut);
assert.equal(query.query, 'virtual microphone mixer');
assert.equal(query.results.length, 2);
assert.equal('embedding' in query.results[0], false);
assert.equal(typeof query.results[0].score, 'number');

console.log('semantic vector index smoke test passed');
