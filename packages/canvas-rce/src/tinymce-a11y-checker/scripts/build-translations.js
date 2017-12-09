'use strict'

const fs = require('fs')
const { join, basename } = require('path')
const { promisify } = require('util')

const readdir = promisify(fs.readdir)
const writeFile = promisify(fs.writeFile)

const LOCALES_DIR = join(__dirname, '..', 'locales')
const TRANSLATIONS_JSON = join(__dirname, '..', 'src', 'translations.json')

const buildEmpty = process.argv.indexOf('--empty') > -1


async function run () {
  const locales = {}
  if (!buildEmpty) {
    const localeFiles = await readdir(LOCALES_DIR)
    for (let file of localeFiles) {
      const code = basename(file, '.json')
      const locale = require(join(LOCALES_DIR, file))
      for (let key in locale) {
        locale[key] = locale[key].message
      }
      locales[code] = locale
    }
  }
  await writeFile(TRANSLATIONS_JSON, JSON.stringify(locales, null, 2))
  console.log(`Locales written to ${TRANSLATIONS_JSON}`)
}

run().catch(console.error)

