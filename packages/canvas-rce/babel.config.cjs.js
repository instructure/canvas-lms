/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
  assumptions: {
    setPublicClassFields: true,
  },
  presets: [
    '@babel/preset-typescript',
    ['@babel/preset-env', {modules: 'commonjs'}],
    ['@babel/preset-react', {useBuiltIns: true}],
    [
      '@instructure/babel-preset-pretranslated-translations-package-format-message',
      {
        translationsDir: 'lib/canvas-rce',
        extractDefaultTranslations: false,
      },
    ],
  ],
  plugins: [
    ['babel-plugin-typescript-to-proptypes'],
    [
      'transform-inline-environment-variables',
      {
        include: ['BUILD_LOCALE'],
      },
    ],
    ['@babel/plugin-proposal-decorators', {legacy: true}],
  ],
}
