/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

const {join, resolve} = require('path')
const {canvasDir} = require('../params')
const {globPlugins} = require('./webpack.utils')

exports.instUIWorkaround =
  // remove when you no longer get an error from @instructure/ui* around
  // import/export with a package not marked as ESM:
  //
  //     ERROR in ./node_modules/@instructure/ui-view/es/index.js 24:0
  //     Module parse failed: 'import' and 'export' may appear only with 'sourceType: module' (24:0)
  //     You may need an appropriate loader to handle this file type, currently no loaders are configured to process this file. See https://webpack.js.org/concepts#loaders
  //
  {
    test: /\.js$/,
    type: 'javascript/auto',
    include: [
      resolve(canvasDir, 'node_modules/@instructure'),
      ...globPlugins('/node_modules/@instructure'),
    ],
  }

exports.webpack5Workaround =
  // packages that do specify "type": "module" for their package but are
  // still using non-fully qualified relative imports (e.g. "./foo"
  // instead of "./foo.js") are rejected by webpack 5, and this works
  // around it in the meantime
  //
  // to reproduce in the future, disable this rule block and verify that
  // webpack compiles successfully without errors like:
  //
  //     BREAKING CHANGE: The request '../jsutils/inspect' failed to
  //     resolve only because it was resolved as fully specified
  //
  // refs: https://github.com/webpack/webpack/issues/11467#issuecomment-691873586
  //       https://github.com/babel/babel/issues/12058
  //       https://github.com/graphql/graphql-js/issues/2721
  {
    test: /\.m?js$/,
    type: 'javascript/auto',
    include: [resolve(canvasDir, 'node_modules/graphql')],
    resolve: {
      fullySpecified: false,
    },
  }

exports.css = {
  test: /\.css$/i,
  type: 'css',
}

exports.images = {
  test: /\.(png|jpe?g|svg|gif)$/i,
  type: 'asset/resource',
}

exports.fonts = {
  test: /\.(woff(2)?|otf|ttf|eot)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
  use: 'file-loader',
}

const browserTargets = {
  browsers: 'last 2 versions',
}

const isCrystalballEnabled = process.env.CRYSTALBALL_MAP === '1'

exports.swc = [
  {
    test: /\.(j|t)s$/,
    include: [resolve(canvasDir, 'ui'), ...globPlugins('app/{jsx,coffeescripts}/')],
    exclude: /(node_modules)/,
    use: {
      // we can use rspack's builtin:swc-loader later when it supports SWC plugins
      loader: isCrystalballEnabled ? 'swc-loader' : 'builtin:swc-loader',
      options: {
        parseMap: true,
        sourceMaps: true,
        jsc: {
          externalHelpers: true,
          parser: {
            syntax: 'typescript',
          },
          ...(isCrystalballEnabled
            ? {
                experimental: {
                  plugins: [['swc-plugin-coverage-instrument', {}]].filter(Boolean),
                },
              }
            : undefined),
        },
        env: {
          targets: browserTargets,
        },
      },
    },
  },
  {
    test: /\.(j|t)sx$/,
    include: [resolve(canvasDir, 'ui'), ...globPlugins('app/{jsx,coffeescripts}/')],
    exclude: /(node_modules)/,
    use: {
      // we can use rspack's builtin:swc-loader later when it supports SWC plugins
      loader: isCrystalballEnabled ? 'swc-loader' : 'builtin:swc-loader',
      options: {
        parseMap: true,
        sourceMaps: true,
        jsc: {
          externalHelpers: true,
          parser: {
            syntax: 'typescript',
            tsx: true,
          },
          ...(isCrystalballEnabled
            ? {
                experimental: {
                  plugins: [['swc-plugin-coverage-instrument', {}]].filter(Boolean),
                },
              }
            : undefined),
        },
        env: {
          targets: browserTargets,
        },
      },
    },
  },
]

exports.handlebars = {
  test: /\.handlebars$/,
  include: [resolve(canvasDir, 'ui'), ...globPlugins('app/views/jst/')],
  use: [
    {
      loader: require.resolve('./i18nLinerHandlebars'),
      options: {
        // brandable_css assets are not available in test
        injectBrandableStylesheet: process.env.NODE_ENV !== 'test',
      },
    },
  ],
}

exports.emberHandlebars = {
  test: /\.hbs$/,
  include: [join(canvasDir, 'ui/features/screenreader_gradebook/jst')],
  use: [require.resolve('./emberHandlebars')],
}

// since istanbul-instrumenter-loader adds so much overhead,
// only use it when generating crystalball map
// i.e. process.env.CRYSTALBALL_MAP === '1'
exports.istanbul = {
  test: /\.(js|jsx|ts|tsx)$/,
  include: [
    resolve(canvasDir, 'ui'),
    resolve(canvasDir, 'spec/javascripts/jsx'),
    resolve(canvasDir, 'spec/coffeescripts'),
    ...globPlugins('app/{jsx,coffeescripts}/'),
  ],
  exclude: [/test\//, /spec/],
  use: {
    loader: 'coverage-istanbul-loader',
    options: {esModules: true, produceSourceMap: true},
  },
  enforce: 'post',
}
