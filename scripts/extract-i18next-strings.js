#!/usr/bin/env node
/*
 * Copyright (C) 2026 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * Extract i18next translation strings from canvas-lms source files.
 *
 * Scans for useTranslation('namespace') and t('key') calls,
 * outputs to packages/translations/lib/canvas-lms/en.json.
 *
 * Usage: node scripts/extract-i18next-strings.js
 */

const fs = require('fs')
const path = require('path')
const {execSync} = require('child_process')

const ROOT = path.resolve(__dirname, '..')
const OUTPUT = path.join(ROOT, 'packages/translations/lib/canvas-lms/en.json')

// Find all .ts/.tsx files that import from @canvas/i18next
const files = execSync(
  'grep -rl "from \'@canvas/i18next\'" ui/features ui/shared --include="*.ts" --include="*.tsx" 2>/dev/null || true',
  {cwd: ROOT, encoding: 'utf8'},
)
  .trim()
  .split('\n')
  .filter(Boolean)

const namespaces = {}

for (const file of files) {
  const content = fs.readFileSync(path.join(ROOT, file), 'utf8')

  // Extract namespace from useTranslation('namespace')
  const nsMatches = content.matchAll(/useTranslation\s*\(\s*['"]([^'"]+)['"]\s*\)/g)
  const fileNamespaces = new Set()
  for (const match of nsMatches) {
    fileNamespaces.add(match[1])
  }

  if (fileNamespaces.size === 0) continue

  // Extract keys from t('key') or t("key") calls.
  // Uses quote-aware matching: single-quoted strings stop at ', double-quoted at ".
  // This handles apostrophes in double-quoted strings like t("students' scores").
  const keyMatches = [
    ...content.matchAll(/(?<![.\w])t\s*\(\s*'([^']+)'\s*[),]/g),
    ...content.matchAll(/(?<![.\w])t\s*\(\s*"([^"]+)"\s*[),]/g),
  ]
  const keys = []
  for (const match of keyMatches) {
    keys.push(match[1])
  }

  // Add keys to each namespace found in this file
  for (const ns of fileNamespaces) {
    if (!namespaces[ns]) namespaces[ns] = {}
    for (const key of keys) {
      namespaces[ns][key] = key
    }
  }
}

// Sort namespaces and keys
const sorted = {}
for (const ns of Object.keys(namespaces).sort()) {
  sorted[ns] = {}
  for (const key of Object.keys(namespaces[ns]).sort()) {
    sorted[ns][key] = namespaces[ns][key]
  }
}

fs.mkdirSync(path.dirname(OUTPUT), {recursive: true})
fs.writeFileSync(OUTPUT, JSON.stringify(sorted, null, 2) + '\n')

const totalKeys = Object.values(sorted).reduce((sum, ns) => sum + Object.keys(ns).length, 0)
console.log(`Extracted ${totalKeys} keys across ${Object.keys(sorted).length} namespaces`)
console.log(`Written to ${path.relative(ROOT, OUTPUT)}`)
