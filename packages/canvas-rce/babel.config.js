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
module.exports = {
  presets: [
    [
      '@instructure/ui-babel-preset',
      {
        coverage: process.env.BABEL_ENV === 'test-node',
        transformImports: false,
        node: ['test-node', 'test'].includes(process.env.BABEL_ENV) || process.env.JEST_WORKER_ID,
        esModules: !(
          ['test-node', 'test'].includes(process.env.BABEL_ENV) || process.env.JEST_WORKER_ID
        )
      }
    ],
    [
      '@instructure/babel-preset-pretranslated-format-message',
      {
        translationsDir: 'locales',
        extractDefaultTranslations: false
      }
    ]
  ],
  plugins: [
    'inline-json-import',
    [
      'transform-inline-environment-variables',
      {
        include: ['BUILD_LOCALE']
      }
    ],
    'minify-constant-folding',
    'minify-guarded-expressions',
    'minify-dead-code-elimination'
  ]
}
