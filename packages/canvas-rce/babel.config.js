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

  env: {
    development: {
      plugins: ['babel-plugin-typescript-to-proptypes'],
    },
    production: {
      plugins: [
        '@babel/plugin-transform-react-constant-elements',
        '@babel/plugin-transform-react-inline-elements',
        'minify-constant-folding',
        'minify-dead-code-elimination',
        'minify-guarded-expressions',
        'transform-react-remove-prop-types',
      ],
    },
  },

  presets: [
    '@babel/preset-typescript',
    [
      '@babel/preset-env',
      {
        useBuiltIns: 'entry',
        corejs: '3.20',
        modules: false,
        include: [
          // This is needed to fix a Safari < 16 bug
          // https://github.com/babel/babel/issues/14289
          // https://bugs.webkit.org/show_bug.cgi?id=236843
          '@babel/plugin-proposal-class-properties',

          // This is needed because New Quizzes build isn't configured to handle the ?? operator
          '@babel/plugin-proposal-nullish-coalescing-operator',
        ],
      },
    ],
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
    [
      'transform-inline-environment-variables',
      {
        include: ['BUILD_LOCALE'],
      },
    ],

    [
      '@babel/plugin-transform-runtime',
      {
        corejs: 3,
        helpers: true,
        useESModules: true,
        regenerator: true,
      },
    ],

    ['@babel/plugin-proposal-decorators', {legacy: true}],
  ],

  targets: {
    browsers: 'last 2 versions',
    esmodules: true,
  },
}
