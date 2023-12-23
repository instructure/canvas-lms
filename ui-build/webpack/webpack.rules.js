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
      resolve(canvasDir, 'packages/canvas-media/node_modules/@instructure'),
      resolve(canvasDir, 'packages/canvas-rce/node_modules/@instructure'),
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
    include: [
      resolve(canvasDir, 'node_modules/graphql'),
      resolve(canvasDir, 'packages/datetime-moment-parser/index.js'),
    ],
    resolve: {
      fullySpecified: false,
    },
  }

exports.css = {
  test: /\.css$/,
  use: ['style-loader', 'css-loader'],
}

exports.images = {
  test: /\.(png|svg|gif)$/,
  loader: 'file-loader',
}

exports.fonts = {
  test: /\.(woff(2)?|otf|ttf|eot)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
  use: 'file-loader',
}

exports.babel = {
  test: /\.(js|ts|jsx|tsx)$/,
  include: [
    resolve(canvasDir, 'ui'),
    resolve(canvasDir, 'packages/jquery-kyle-menu'),
    resolve(canvasDir, 'packages/jquery-popover'),
    resolve(canvasDir, 'packages/jquery-selectmenu'),
    resolve(canvasDir, 'packages/convert-case'),
    resolve(canvasDir, 'packages/slickgrid'),
    resolve(canvasDir, 'packages/with-breakpoints'),
    resolve(canvasDir, 'spec/javascripts/jsx'),
    resolve(canvasDir, 'spec/coffeescripts'),
    ...globPlugins('app/{jsx,coffeescripts}/'),
  ],
  exclude: [/node_modules/],
  parser: {
    requireInclude: 'allow',
  },
  use: {
    loader: 'babel-loader',
    options: {
      configFile: false,
      cacheDirectory: process.env.NODE_ENV !== 'production',
      assumptions: {
        setPublicClassFields: true,
      },
      env: {
        development: {
          plugins: ['babel-plugin-typescript-to-proptypes'],
        },
        production: {
          plugins: [
            [
              '@babel/plugin-transform-runtime',
              {
                helpers: true,
                corejs: 3,
                useESModules: true,
              },
            ],
            'transform-react-remove-prop-types',
            '@babel/plugin-transform-react-inline-elements',
            '@babel/plugin-transform-react-constant-elements',
          ],
        },
      },
      presets: [
        ['@babel/preset-typescript'],
        [
          '@babel/preset-env',
          {
            useBuiltIns: 'entry',
            corejs: '3.20',
            modules: false,
            // This is needed to fix a Safari < 16 bug
            // https://github.com/babel/babel/issues/14289
            // https://bugs.webkit.org/show_bug.cgi?id=236843
            include: ['@babel/plugin-proposal-class-properties'],
          },
        ],
        ['@babel/preset-react', {useBuiltIns: true}],
      ],
      targets: {
        browsers: 'last 2 versions',
        esmodules: true,
      },
    },
  },
}

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
  test: /\.(js|ts|tsx)$/,
  include: [
    resolve(canvasDir, 'ui'),
    resolve(canvasDir, 'packages/jquery-kyle-menu'),
    resolve(canvasDir, 'packages/jquery-popover'),
    resolve(canvasDir, 'packages/jquery-selectmenu'),
    resolve(canvasDir, 'packages/slickgrid'),
    resolve(canvasDir, 'packages/with-breakpoints'),
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
