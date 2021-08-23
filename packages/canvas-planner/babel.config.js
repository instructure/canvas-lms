/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
    ]
  ],
  plugins: [
    'inline-react-svg',
    // something changed in @instructure/ui-babel-preset that necessitated
    // @babel/plugin-proposal-private-methods, {loose: true}
    // to stop the build from flooding the console output with warnings.
    // then that broke decorators, which RCEWrapper uses. The other
    // 2 plugin-proposal-* plugins fix that and get rid of the wornings
    ['@babel/plugin-proposal-decorators', {legacy: true}],
    ['@babel/plugin-proposal-class-properties', {loose: true}],
    ['@babel/plugin-proposal-private-methods', {loose: true}]
  ]
}
