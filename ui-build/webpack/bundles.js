/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

const fs = require('fs')
const {getAppFeatureBundles, getPluginBundles} = require('./webpack.utils')
const momentLocaleBundles = require('./momentBundles')

// generates file with functions that dynamically import each feature and plugin bundle
// TODO: use proper separate webpack entries
fs.writeFileSync(
  './node_modules/bundles-generated.js',
  `

if (typeof ENV !== 'undefined' && ENV.MOMENT_LOCALE && ENV.MOMENT_LOCALE !== 'en') {
  function loadLocale(locale) {
    switch (locale) {
      ${Object.entries(momentLocaleBundles)
        .map(
          ([assetName, jsFile]) => `
        case "${assetName}": return import(/* webpackChunkName: "${assetName}" */ "${jsFile}");
      `
        )
        .join('')}

      default:
        console.warn("couldn't load moment/locale/", locale)
    }
  }
  loadLocale('moment/locale/' + ENV.MOMENT_LOCALE)
}

export default function loadBundle(bundleName) {
  switch (bundleName) {
    ${[...getAppFeatureBundles(), ...getPluginBundles()]
      .map(
        ([entryName, entryBundlePath]) => `
      case "${entryName}": return import(/* webpackChunkName: "${entryName}" */ "${entryBundlePath}");
    `
      )
      .join('')}

    default:
      throw new Error("couldn't find bundle " + bundleName)
  }
}
`
)
