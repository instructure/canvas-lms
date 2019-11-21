#!/usr/bin/env node
/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

const fs = require('fs').promises
const path = require('path')

const TRANSLATION_PATH = path.resolve('lib')
const PACKAGES_DIR = path.resolve('..')

async function getTranslationFiles() {
  const dirents = await fs.readdir(TRANSLATION_PATH, {withFileTypes: true})
  return dirents.filter(dirent => !dirent.isDirectory()).map(dirent => dirent.name)
}

function getPackageList() {
  return fs.readdir(PACKAGES_DIR)
}

async function getEnglishSourceFilePaths() {
  const packages = await getPackageList()
  return packages
    .filter(packageName => !packageName.startsWith('.'))
    .map(packageName => ({
      englishPath: `${packageName}/locales/en.json`,
      packageName
    }))
}

async function splitStrings() {
  const files = await getTranslationFiles()

  const sources = await getEnglishSourceFilePaths()
  return Promise.all(
    sources.map(async source => {
      try {
        // eslint-disable-next-line import/no-dynamic-require
        const englishStrings = require(source.englishPath)
        try {
          await fs.mkdir(`${TRANSLATION_PATH}/${source.packageName}`)
        } catch (e) {
          if (e.code !== 'EEXIST') {
            // If it's just telling us the directory is already there,
            // ignore it and move on, but if it is a different error throw it again.
            throw e
          }
        }

        const englishKeys = Object.keys(englishStrings)
        return Promise.all(
          files.map(async languageFile => {
            if (languageFile.startsWith('.')) {
              return
            }
            const newLanguage = {}
            // These are individual language files we care about.
            // eslint-disable-next-line import/no-dynamic-require
            const translatedStrings = require(`../lib/${languageFile}`)
            englishKeys.forEach(ek => {
              newLanguage[ek] = translatedStrings[ek]
            })
            return fs.writeFile(
              `${TRANSLATION_PATH}/${source.packageName}/${languageFile}`,
              JSON.stringify(newLanguage)
            )
          })
        )
      } catch (e) {
        // eslint-disable-next-line no-console
        console.warn(`No English strings for ${source.packageName}`)
      }
    })
  )
}

module.exports = splitStrings
