/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

const glob = require('glob')
const path = require('path')

// Put any custom moment locales here:
const customMomentLocales = ['de', 'fa', 'fr', 'fr-ca', 'he', 'ht-ht', 'hy-am', 'mi-nz', 'pl']

const momentLocaleBundles = glob
  .sync('moment/locale/**/*.js', {cwd: 'node_modules'})
  .reduce((memo, filename) => {
    const parsed = path.parse(filename)
    if (!customMomentLocales.includes(parsed.name)) {
      memo[`${parsed.dir}/${parsed.name}`] = filename
    }
    return memo
  }, {})

customMomentLocales.forEach(locale => {
  const filename = `custom_moment_locales/${locale.replace('-', '_')}.js`
  momentLocaleBundles[`moment/locale/${locale}`] = filename
})

module.exports = momentLocaleBundles
