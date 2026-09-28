#!/usr/bin/env node

/**
 * verify_features_i18n.js
 *
 * Verifies that zero hardcoded Chinese strings remain across all Swift files
 * in Floreboard/Features/.
 */

const fs = require('fs');
const path = require('path');

const FEATURES_DIR = path.resolve(__dirname, '../Floreboard/Features');

const CHINESE_REGEX = /"([^"\n]*[\u4e00-\u9fa5]+[^"\n]*)"/g;

function getSwiftFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  for (const file of list) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat && stat.isDirectory()) {
      results = results.concat(getSwiftFiles(filePath));
    } else if (file.endsWith('.swift')) {
      results.push(filePath);
    }
  }
  return results;
}

const files = getSwiftFiles(FEATURES_DIR);
console.log(`Scanning ${files.length} Swift files in Floreboard/Features/ for hardcoded Chinese strings...`);

const violations = [];

for (const filePath of files) {
  const relPath = path.relative(path.resolve(__dirname, '..'), filePath);
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');

  lines.forEach((line, idx) => {
    const trimmed = line.trim();
    if (trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) {
      return;
    }
    const matches = line.match(CHINESE_REGEX);
    if (matches) {
      for (const m of matches) {
        violations.push({
          file: relPath,
          line: idx + 1,
          matched: m
        });
      }
    }
  });
}

if (violations.length === 0) {
  console.log('✅ SUCCESS: Exactly 0 hardcoded Chinese strings found in Floreboard/Features/!');
  process.exit(0);
} else {
  console.error(`❌ FAILURE: Found ${violations.length} hardcoded Chinese string(s):`);
  violations.forEach(v => {
    console.error(`  - ${v.file}:${v.line} -> ${v.matched}`);
  });
  process.exit(1);
}
