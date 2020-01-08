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

// Generates all the pre-translated code in lib/translated/{locale}.

const shell = require('shelljs')
const promisify = require('util').promisify
const exec = promisify(require('child_process').exec)
const getTranslationList = require('@instructure/translations/bin/get-translation-list')

shell.set('-e')
shell.rm('-rf', 'lib/')
const npm_bin_path = shell.exec('npm bin').trim()

shell.echo('Building CommonJS version')
shell.exec(`TRANSFORM_IMPORTS=1 ${npm_bin_path}/babel --out-dir lib src`)

shell.echo('Building ES Modules version')
shell.exec(`ES_MODULES=1 ${npm_bin_path}/babel --out-dir lib/modules src`)

shell.echo(`building pretranslated output in lib/translated in mulitple processes`)
getTranslationList('canvas-rce')
  .then(translationFiles => {
    const locales = translationFiles.map(tf => tf.split('.')[0])
    const processPromises = locales.map(locale => {
      return exec(
        `BUILD_LOCALE=${locale} ${npm_bin_path}/babel --out-dir lib/translated/${locale}/modules --ignore locales* src`
      )
    })
    Promise.all(processPromises)
      .then(() => {
        console.log('Translations complete')
      })
      .catch(e => {
        throw e
      })
  })
  .catch(e => console.error(e))
