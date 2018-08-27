/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2018 - present Instructure, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

const fs = require('fs')
const path = require('path')

module.exports = function babelPresetPretranslatedFormatMessage (context, opts = {}) {
  return {
    plugins: getFormatMessageConfig(opts)
  }
}

function getFormatMessageConfig ({
  translationsDir = 'translations',
  extractDefaultTranslations = process.env.NODE_ENV !== 'test'
}) {
  let formatMessageConfig = []

  // if a BUILD_LOCALE environment variable is set, generate pre-translated source for that language,
  const BUILD_LOCALE = process.env.BUILD_LOCALE
  if (BUILD_LOCALE) {
    formatMessageConfig = [
      ['transform-format-message', {
        generateId: 'underscored_crc32',
        inline: true,
        locale: BUILD_LOCALE,
        translations: {
          [BUILD_LOCALE]: require(path.join(process.cwd(), translationsDir, BUILD_LOCALE))
        }
      }]
    ]

  // In test mode, sometimes we are only dealing with a subset of files so if we extracted strings we'd be missing some
  } else if (extractDefaultTranslations) {
    try {
      fs.accessSync(path.join(process.cwd(), translationsDir, 'en.json'), fs.W_OK)
      formatMessageConfig = [
        ['extract-format-message', {
          generateId: 'underscored_crc32',
          outFile: 'translations/en.json'
        }]
      ]
    } catch (e) {
      // Skip string extraction since we don't have write access to translations/en.json
    }
  }
  return formatMessageConfig
}