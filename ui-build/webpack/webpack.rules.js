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

const {resolve} = require('path')
const {canvasDir} = require('../params')
const {globPlugins} = require('./webpack.utils')

// inline global and module CSS into JS using style-loader and css-loader
// https://rspack.dev/guide/tech/css
exports.css = {
  test: /\.css$/i,
  oneOf: [
    {
      test: /\.module\.css$/i,
      use: [
        'style-loader',
        {
          loader: 'css-loader',
          options: {
            // https://rspack.dev/config/module
            modules: {
              // customizes class names for easier debugging by preserving the local name and adding
              // a shortened 5-character hash, improving readability while keeping names unique;
              // the default output is more complex (e.g. _1Aa3laeKiSGA1j6c1SlITH), whereas this
              // change produces a simpler, easier-to-debug name (e.g. pageWrapper__1Aa3l)
              localIdentName: '[local]__[hash:base64:5]',
            },
          },
        },
      ],
    },
    {
      use: ['style-loader', 'css-loader'],
    },
  ],
  type: 'javascript/auto',
}

exports.images = {
  test: /\.(png|jpe?g|svg|gif)$/i,
  type: 'asset/resource',
}

exports.fonts = {
  test: /\.(woff(2)?|otf|ttf|eot)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
  use: 'asset/resource',
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
        // if isCrystalballEnabled is true, set parseMap to true
        ...(isCrystalballEnabled ? {parseMap: true} : {}),
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
        ...(isCrystalballEnabled ? {parseMap: true} : {}),
        sourceMaps: true,
        jsc: {
          externalHelpers: true,
          parser: {
            syntax: 'typescript',
            tsx: true,
          },
          transform: {
            react: {
              runtime: 'automatic',
              development: process.env.NODE_ENV === 'development',
              refresh: process.env.NODE_ENV === 'development',
            },
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

// since istanbul-instrumenter-loader adds so much overhead,
// only use it when generating crystalball map
// i.e. process.env.CRYSTALBALL_MAP === '1'
exports.istanbul = {
  test: /\.(js|jsx|ts|tsx)$/,
  include: [resolve(canvasDir, 'ui'), ...globPlugins('app/{jsx,coffeescripts}/')],
  exclude: [/test\//, /spec/],
  use: {
    loader: 'coverage-istanbul-loader',
    options: {esModules: true, produceSourceMap: true},
  },
  enforce: 'post',
}

exports.graphql = {
  test: /\.graphql$/,
  type: 'asset/source',
}
