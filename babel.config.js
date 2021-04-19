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

const USE_ES_MODULES =
  'USE_ES_MODULES' in process.env
    ? process.env.USE_ES_MODULES !== 'false'
    : !process.env.JEST_WORKER_ID

module.exports = {
  presets: [
    [
      '@instructure/ui-babel-preset',
      {
        esModules: USE_ES_MODULES,
        node: !!process.env.JEST_WORKER_ID
      }
    ]
  ],
  plugins: ['@babel/plugin-proposal-optional-chaining'],
  env: {
    production: {
      plugins: [
        'transform-react-remove-prop-types',
        '@babel/plugin-transform-react-inline-elements'
      ]
    }
  }
}

// we can't just use the transformImports option of @instructure/ui-babel-preset because
// @instructure/ui-media-player uses the old pattern of putting things in /components like InstUI used to do
if (!USE_ES_MODULES) {
  module.exports.plugins = [
    '@babel/plugin-proposal-optional-chaining',
    [
      '@instructure/babel-plugin-transform-imports',
      {
        '(@instructure/ui-[^/]+)$': {
          transform: (importName, matches) => {
            if (
              !matches ||
              !matches[1] ||
              matches[1] === '@instructure/ui-test-utils' ||
              matches[1].startsWith('@instructure/ui-media')
            )
              return
            return `${matches[1]}/lib/${importName}`
          }
        }
      }
    ]
  ]
}
