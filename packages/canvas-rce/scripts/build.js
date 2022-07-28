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

// We make this directory if it doesn't exist so that the following delete command works outside of docker.  This
// directory is automatically created via a volume mount when using docker, so the -p flag prevents the mkdir command
// from failing
shell.exec('mkdir -p lib')
shell.exec('mkdir -p es')

// We can't delete this directory when inside docker because it is used as a volume mount point, so instead we
// delete everything in it.
shell.exec('rm -rf lib/*')
shell.exec('rm -rf es/*')
shell.exec('scripts/installTranslations.js')
const npm_bin_path = shell.exec('npm bin').trim()

shell.echo('Building CommonJS version')
shell.exec(
  `JEST_WORKER_ID=1 ${npm_bin_path}/babel --out-dir lib src --ignore '**/__tests__' --extensions '.ts,.tsx,.js,.jsx'`
)

shell.echo('Building ES Modules version')
shell.exec(
  `${npm_bin_path}/babel --out-dir es src --ignore '**/__tests__' --extensions '.ts,.tsx,.js,.jsx'`
)

shell.echo(`building pretranslated output in lib/translated in mulitple processes`)
getTranslationList('canvas-rce')
  .then(translationFiles => {
    const locales = translationFiles.map(tf => tf.split('.')[0])
    const processPromises = locales.map(locale => {
      return exec(
        `BUILD_LOCALE=${locale} ${npm_bin_path}/babel --out-dir lib/translated/${locale}/modules --ignore locales* src --extensions '.ts,.tsx,.js'`
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
