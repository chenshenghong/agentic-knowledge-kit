#!/usr/bin/env node

import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const repoRoot = resolve(new URL('..', import.meta.url).pathname);
const tmp = mkdtempSync(join(tmpdir(), 'agentic-context-test-'));

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
      ],
      links: [],
    },
    null,
    2,
  ),
);

execFileSync(
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

const hookContext = spawnSync(
  'node',
  [
    join(repoRoot, 'scripts', 'agentic-knowledge-context.mjs'),
    '--repo',
    tmp,
    '--provider',
    'test',
    '--dimensions',
    '12',
    '--limit',
    '1',
  ],
  {
    encoding: 'utf8',
    input: JSON.stringify({
      hook_event_name: 'UserPromptSubmit',
      prompt: 'Where is the virtual microphone mixer implemented?',
    }),
  },
);

assert.equal(hookContext.status, 0, hookContext.stderr);
assert.match(hookContext.stdout, /Agentic Knowledge Context/);
assert.match(hookContext.stdout, /mixVirtualAudio/);
assert.match(hookContext.stdout, /src\/audio\.js:1/);
assert.doesNotMatch(hookContext.stdout, /vector\]|embedding/i);

const jsonContext = execFileSync(
  'node',
  [
    join(repoRoot, 'scripts', 'agentic-knowledge-context.mjs'),
    '--repo',
    tmp,
    '--provider',
    'test',
    '--dimensions',
    '12',
    '--json',
    'virtual microphone mixer',
  ],
  { encoding: 'utf8' },
);

const payload = JSON.parse(jsonContext);
assert.equal(payload.available, true);
assert.equal(payload.query, 'virtual microphone mixer');
assert.equal(payload.results.length, 1);
assert.equal(payload.results[0].label, 'mixVirtualAudio');

const missingIndex = spawnSync(
  'node',
  [
    join(repoRoot, 'scripts', 'agentic-knowledge-context.mjs'),
    '--repo',
    join(tmp, 'missing'),
    'anything',
  ],
  { encoding: 'utf8' },
);

assert.equal(missingIndex.status, 0);
assert.equal(missingIndex.stdout, '');
assert.equal(missingIndex.stderr, '');
assert.equal(existsSync(join(tmp, 'semantic-vector-index', 'manifest.json')), true);
assert.equal(typeof JSON.parse(readFileSync(join(tmp, 'semantic-vector-index', 'manifest.json'), 'utf8')).source.graphHash, 'string');

const installer = readFileSync(join(repoRoot, 'scripts', 'install-agentic-knowledge.sh'), 'utf8');
assert.match(installer, /copy_helper_script agentic-knowledge-context\.mjs/);
assert.match(installer, /UserPromptSubmit/);
assert.match(installer, /\.agents\/rules\/agentic-knowledge\.md/);
assert.match(installer, /GEMINI\.md/);

console.log('agentic knowledge context smoke test passed');
