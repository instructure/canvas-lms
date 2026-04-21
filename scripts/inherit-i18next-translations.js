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
 * Inherit existing translations from the old i18n system into i18next format.
 *
 * For each key in packages/translations/lib/canvas-lms/en.json, finds the
 * hashed key in en-js.json, looks it up in each locale's YAML, and writes
 * the translation to packages/translations/lib/canvas-lms/<locale>.json.
 *
 * Usage: node scripts/inherit-i18next-translations.js
 *
 * Requires: run inside the docker web container (needs Ruby YAML parsing)
 *           OR have locale YAMLs accessible and js-yaml installed.
 *
 * For simplicity, this script reads the YAML files line-by-line looking for
 * top-level hashed keys, avoiding the need for a YAML parser.
 */

const fs = require('fs')
const path = require('path')

const ROOT = path.resolve(__dirname, '..')
const EN_JS = path.join(ROOT, 'config/locales/generated/en-js.json')
const LOCALES_DIR = path.join(ROOT, 'config/locales')
const I18NEXT_EN = path.join(ROOT, 'packages/translations/lib/canvas-lms/en.json')
const OUTPUT_DIR = path.join(ROOT, 'packages/translations/lib/canvas-lms')

// Build reverse map: English text → hashed key
const enJs = require(EN_JS)
const englishToHash = {}
for (const [hash, english] of Object.entries(enJs.en)) {
  englishToHash[english] = hash
}

// Read our i18next English file
const i18nextEn = JSON.parse(fs.readFileSync(I18NEXT_EN, 'utf8'))

// Collect all hashed keys we need, grouped by namespace
const needed = {}
for (const [ns, keys] of Object.entries(i18nextEn)) {
  needed[ns] = {}
  for (const englishKey of Object.keys(keys)) {
    const hash = englishToHash[englishKey]
    if (hash) {
      needed[ns][englishKey] = hash
    } else {
      console.warn(`No hash found for "${englishKey}" — new string, no old translation`)
    }
  }
}

const allHashes = new Set()
for (const ns of Object.values(needed)) {
  for (const hash of Object.values(ns)) {
    allHashes.add(hash)
  }
}

// Find all locale YAML files
const yamlFiles = fs
  .readdirSync(LOCALES_DIR)
  .filter(
    f => f.endsWith('.yml') && f !== 'en.yml' && f !== 'locales.yml' && !f.startsWith('generated'),
  )

let localesWritten = 0

for (const yamlFile of yamlFiles) {
  const locale = yamlFile.replace('.yml', '')
  const yamlPath = path.join(LOCALES_DIR, yamlFile)
  const content = fs.readFileSync(yamlPath, 'utf8')

  // Simple line-by-line extraction of top-level hashed keys.
  // YAML structure: locale:\n  hashed_key: "translation"
  // We look for lines like:  acceptable_use_policy_29a28124: "..."
  const translations = {}
  for (const line of content.split('\n')) {
    const match = line.match(/^\s{2,4}(\w+_[0-9a-f]{8})\s*:\s*"(.*)"$/)
    if (match) {
      const [, hash, value] = match
      if (allHashes.has(hash) && value) {
        translations[hash] = value
      }
    }
    // Also handle unquoted values
    const matchUnquoted = line.match(/^\s{2,4}(\w+_[0-9a-f]{8})\s*:\s*(.+)$/)
    if (!match && matchUnquoted) {
      const [, hash, value] = matchUnquoted
      if (allHashes.has(hash) && value.trim() && value.trim() !== '~') {
        translations[hash] = value.trim().replace(/^["']|["']$/g, '')
      }
    }
  }

  // Build i18next locale file
  const output = {}
  let keysFound = 0
  for (const [ns, keys] of Object.entries(needed)) {
    output[ns] = {}
    for (const [englishKey, hash] of Object.entries(keys)) {
      if (translations[hash]) {
        output[ns][englishKey] = translations[hash]
        keysFound++
      }
    }
    // Remove empty namespaces
    if (Object.keys(output[ns]).length === 0) {
      delete output[ns]
    }
  }

  if (keysFound > 0) {
    const outputPath = path.join(OUTPUT_DIR, `${locale}.json`)
    fs.writeFileSync(outputPath, JSON.stringify(output, null, 2) + '\n')
    localesWritten++
    console.log(`${locale}: ${keysFound} translations`)
  }
}

console.log(`\nDone. Wrote ${localesWritten} locale files to packages/translations/lib/canvas-lms/`)
