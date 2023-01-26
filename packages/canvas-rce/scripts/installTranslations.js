#!/usr/bin/env node

/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
 * For each locale there are 2 files we need. One is a .json file with the RCE
 * translations that's managed by the canvas-lms translation process and lives in
 * @instructure/translations. The other is a .js file downloaded from
 * https://www.tiny.cloud/get-tiny/language-packages/.
 * These two sources support different locales and each have their own
 * locale -> file nameing scheme, making it easy to get out of sync.
 *
 * This script uses the list of files in @instructure/translations for the rce as
 * the source of the list of RCE supported locales, maps the tinymce supported locales
 * as closely as possible to them (using src/rce/editorLanguage.js), and generates
 * the set of files the RCE will import which in turn imports both sets of
 * translations data.
 *
 * RCE translations come from @instructure/translations
 * tinymce translations come from src/translations/tinymce
 * the generated locale files are in src/translations/locales
 *
 * In addition, ./src/getTranslations.js is generated which defines a function that
 * imports the right src/translations/locales file based on the given locale. This
 * has the effect of webpack splitting each locales/*.js file into its own bundle.
 *
 * The output from this script gets checked in.
 * This script is run as a prelude to the build, and if no translated data files have
 * changes, it should not generate any changes in its output.
 *
 * If you update the tinymce translation packages (and you should periodically),
 * check the mapping in src/rce/editorLanguages.js to be sure it's still complete.
 */

const shell = require('shelljs')
const fs = require('fs')
const path = require('path')
const getTranslationList = require('@instructure/translations/bin/get-translation-list')
const readTranslationFile = require('@instructure/translations/bin/read-translation-file')
const editorLanguage = require('../src/rce/editorLanguage')

// Here we go.
installTranslations()
  .then(() => {
    console.log('Translations installed.')
    process.exit(0)
  })
  .catch(err => {
    console.error('Failed installing translations', err)
    process.exit(1)
  })

// The driver that does all the work.
async function installTranslations() {
  const canvasTranslations = await getTranslationList()
  const canvasLocaleFileBasenames = canvasTranslations.map(t => t.replace('.json', ''))
  const tinyLocales = mapCanvasLocalesToTiny(canvasLocaleFileBasenames)
  generateCombinedImporters(canvasLocaleFileBasenames, tinyLocales)
  // different file systems return the list of files in different orders
  // (e.g. da vs da-x-k12) so sort them to get a uniform order
  // of the case statements out of generateGetTranslations
  generateGetTranslations(canvasLocaleFileBasenames.sort())
}

// given the array of canvas locales, return
// the mapping to the corresponding tinymce locales
function mapCanvasLocalesToTiny(canvasLocales) {
  const tinyLocales = {}
  for (const locale of canvasLocales) {
    tinyLocales[locale] = editorLanguage(locale)
  }
  return tinyLocales
}

// there's one file in src/translations/locales for each canvas locale
// that imports adds the canvas strings to formatMessage and
// imports the corresponding tinymce translations if one exists
function generateCombinedImporters(canvasLocaleFileBasenames, tinyLocales) {
  removeStaleTranslationFiles(canvasLocaleFileBasenames)

  for (const basename of canvasLocaleFileBasenames) {
    const filepath = path.resolve(
      __dirname,
      path.join('../src/translations/locales', `${basename}.js`)
    )
    const content = localeFileContent(basename, tinyLocales[basename])
    fs.writeFileSync(filepath, content, {flag: 'w'})
  }
}

// if there are any existing src/translations/locales files
// for locales no longer in the new list, remove them
function removeStaleTranslationFiles(locales) {
  const newLocalesFiles = locales.map(l => `${l}.js`)
  const curLocalesFiles = fs.readdirSync(path.resolve(__dirname, `../src/translations/locales`))
  const staleFiles = curLocalesFiles.filter(f => !newLocalesFiles.includes(f))
  for (f of staleFiles) {
    fs.rmSync(path.resolve(__dirname, path.join('../src/translations/locales/', f)))
  }
}

const copyright = `/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
`

// the content of the file being generated in generateCombinedImporters
function localeFileContent(canvasLocaleFileBasename, tinyLocale) {
  // some translation files have '_', but no canvas locale does,
  // they all use '-'.
  let canvasLocale = canvasLocaleFileBasename.replace(/_/g, '-')
  const localeData = readTranslationFile('canvas-rce', canvasLocaleFileBasename)

  const preface = `${copyright}
import formatMessage from '../../format-message'
`
  const tinyimport = tinyLocale
    ? `import '../tinymce/${tinyLocale}'
`
    : ''

  const rceLocaleDef = `
const locale = ${localeData}
`

  if (/-/.test(canvasLocale)) {
    canvasLocale = `'${canvasLocale}'`
  }

  const trailer = `
formatMessage.addLocale({${canvasLocale}: locale})
`

  return `${preface}${tinyimport}${rceLocaleDef}${trailer}`
}

// generate the getTranslations() function
// that serves to code-split the translations
// into their own webpack bundle then provide
// them to the RCE
function generateGetTranslations(localeFileBasenames) {
  const preface = `${copyright}
/*
 * ********************************************************
 * This file is generated by scripts/installTranslations.js
 * as part of the build. DO NOT EDIT
 * ********************************************************
 */

export default function getTranslations(locale) {
  const transReadyPromise = new Promise((resolve, reject) => {
    import('tinymce')
      .then(() => {
        let p
        switch (locale) {
`

  const cases = []
  for (const locale of localeFileBasenames) {
    cases.push(`          case '${locale.replace(/_/g, '-')}':
            p = import('./translations/locales/${locale}')
            break`)
  }

  const trailer = `
          default:
            p = Promise.resolve(null)
        }
        p.then(resolve).catch(reject)
      })
      .catch(() => {
        throw new Error('Failed loading tinymce.')
      })
  })
  return transReadyPromise
}
`
  const getlocalelist = `
export function getLocaleList() {
  return [
    '${localeFileBasenames.map(l => l.replace(/_/g, '-')).join("',\n    '")}',
  ]
}
`
  const content = `${preface}${cases.join('\n')}${trailer}${getlocalelist}`

  fs.writeFileSync('./src/getTranslations.js', content, {flag: 'w'})
}
