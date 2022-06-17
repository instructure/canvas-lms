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

const path = require('path')
const glob = require('glob')
const { DefinePlugin, EnvironmentPlugin } = require('webpack')
const partitioning = require('./partitioning')
const PluginSpecsRunner = require('./PluginSpecsRunner')
const { canvasDir } = require('#params')

const {
  CONTEXT_COFFEESCRIPT_SPEC,
  CONTEXT_EMBER_GRADEBOOK_SPEC,
  CONTEXT_JSX_SPEC,
  RESOURCE_COFFEESCRIPT_SPEC,
  RESOURCE_EMBER_GRADEBOOK_SPEC,
  RESOURCE_JSA_SPLIT_SPEC,
  RESOURCE_JSG_SPLIT_SPEC,
  RESOURCE_JSH_SPLIT_SPEC,
  RESOURCE_JSX_SPEC,
} = partitioning

const WEBPACK_PLUGIN_SPECS = path.join(canvasDir, 'tmp/webpack-plugin-specs.js')

module.exports = {
  mode: 'development',
  module: {
    noParse: [
      require.resolve('@instructure/i18nliner/dist/lib/i18nliner.js'),
      require.resolve('jquery'),
      require.resolve('tinymce'),
    ],
    rules: [
      {
        test: /\.(js|ts|tsx)$/,
        include: [
          path.join(canvasDir, 'ui'),
          path.join(canvasDir, 'packages/jquery-kyle-menu'),
          path.join(canvasDir, 'packages/jquery-sticky'),
          path.join(canvasDir, 'packages/jquery-popover'),
          path.join(canvasDir, 'packages/jquery-selectmenu'),
          path.join(canvasDir, 'packages/mathml'),
          path.join(canvasDir, 'packages/persistent-array'),
          path.join(canvasDir, 'packages/slickgrid'),
          path.join(canvasDir, 'packages/with-breakpoints'),
          path.join(canvasDir, 'spec/javascripts/jsx'),
          path.join(canvasDir, 'spec/coffeescripts'),
          /gems\/plugins\/.*\/app\/(jsx|coffeescripts)\//
        ],
        exclude: [/node_modules/],
        use: {
          loader: 'babel-loader',
          options: {
            cacheDirectory: false,
            configFile: false,
            presets: [
              ['@babel/preset-react', { useBuiltIns: true }],
              ['@babel/preset-typescript'],
            ],
            plugins: [
              // we need to have babel transpile ESM to CJS and can't just let
              // Webpack do it because Sinon is evidently no longer compatible
              // with the way Webpack 4 does CJS in as far as spying on module
              // symbols is concerned
              '@babel/plugin-transform-modules-commonjs',
              '@babel/plugin-proposal-optional-chaining',
              '@babel/plugin-proposal-class-properties'
            ]
          }
        }
      },
      {
        test: /\.coffee$/,
        include: [
          path.join(canvasDir, 'ui'),
          path.join(canvasDir, 'spec/coffeescripts'),
          path.join(canvasDir, 'packages/backbone-input-filter-view/src'),
          path.join(canvasDir, 'packages/backbone-input-view/src'),
        ].concat(
          glob.sync('gems/plugins/*/{app,spec_canvas}/coffeescripts/', {
            cwd: canvasDir,
            absolute: true
          })
        ),
        use: ['coffee-loader']
      },
      {
        test: /\.handlebars$/,
        include: [
          path.join(canvasDir, 'ui'),
          /gems\/plugins\/.*\/app\/views\/jst\//
        ],
        use: [
          {
            loader: require.resolve('#webpack-i18nliner-handlebars-loader'),
            options: {
              // brandable_css assets are not available in test
              injectBrandableStylesheet: false
            }
          }
        ]
      },
      {
        test: /\.hbs$/,
        include: [path.join(canvasDir, 'ui/features/screenreader_gradebook/jst')],
        use: [require.resolve('#webpack-ember-handlebars-loader')]
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      },
      {
        test: /\.(png|svg|gif)$/,
        loader: 'file-loader'
      },
      {
        test: /\.(woff(2)?|otf|ttf|eot)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        use: 'file-loader'
      },

      // Our spec files expect qunit's global `test`, `module`, `asyncTest` and
      // `start` variables. These imports loaders make it so they are avalable
      // as local variables inside of a closure, without truly making them
      // globals. We should get rid of this and just change our actual source to
      // s/test/qunit.test/ and s/module/qunit.module/
      {
        test: /\.js$/,
        include: [
          path.join(canvasDir, 'spec/coffeescripts'),
          path.join(canvasDir, 'spec/javascripts/jsx'),
        ].concat(
          glob.sync('gems/plugins/*/spec_canvas/coffeescripts/', {
            cwd: canvasDir,
            absolute: true
          })
        ),

        use: ['imports-loader?test=>QUnit.test']
      },
    ]
  },
  resolve: {
    alias: {
      ['d3']: 'd3/d3',
      ['node_modules-version-of-backbone$']: require.resolve('backbone'),
      ['node_modules-version-of-react-modal$']: require.resolve('react-modal'),
      ['spec/jsx']: path.join(canvasDir, 'spec/javascripts/jsx'),
      ['ui/boot/initializers']: path.join(canvasDir, 'ui/boot/initializers'),
      ['ui/ext']: path.join(canvasDir, 'ui/ext'),
      ['ui/features']: path.join(canvasDir, 'ui/features'),
      [CONTEXT_COFFEESCRIPT_SPEC]: path.join(canvasDir, CONTEXT_COFFEESCRIPT_SPEC),
      [CONTEXT_EMBER_GRADEBOOK_SPEC]: path.join(canvasDir, CONTEXT_EMBER_GRADEBOOK_SPEC),
      [CONTEXT_JSX_SPEC]: path.join(canvasDir, CONTEXT_JSX_SPEC),
    },
    extensions: ['.mjs', '.js', '.ts', '.tsx', '.coffee'],
    modules: [
      path.join(canvasDir, 'ui/shims'),
      path.join(canvasDir, 'public/javascripts'),
      path.join(canvasDir, 'gems/plugins'),
      path.join(canvasDir, 'spec/coffeescripts'),
      'node_modules'
    ],
  },

  resolveLoader: {
    modules: ['node_modules', path.resolve(__dirname, '../webpack')]
  },

  plugins: [
    new DefinePlugin({
      CONTEXT_COFFEESCRIPT_SPEC: JSON.stringify(CONTEXT_COFFEESCRIPT_SPEC),
      CONTEXT_EMBER_GRADEBOOK_SPEC: JSON.stringify(CONTEXT_EMBER_GRADEBOOK_SPEC),
      CONTEXT_JSX_SPEC: JSON.stringify(CONTEXT_JSX_SPEC),
      RESOURCE_COFFEESCRIPT_SPEC,
      RESOURCE_EMBER_GRADEBOOK_SPEC,
      RESOURCE_JSX_SPEC,
      WEBPACK_PLUGIN_SPECS: JSON.stringify(WEBPACK_PLUGIN_SPECS)
    }),

    new EnvironmentPlugin({
      JSPEC_PATH: null,
      JSPEC_GROUP: null,
      JSPEC_RECURSE: '1',
      JSPEC_VERBOSE: '0',
      A11Y_REPORT: false,
      GIT_COMMIT: null
    }),

    new PluginSpecsRunner({
      pattern: 'gems/plugins/*/spec_canvas/coffeescripts/**/*Spec.js',
      outfile: WEBPACK_PLUGIN_SPECS
    }),
  ].concat(
    process.env.JSPEC_GROUP ? [
      partitioning.createPlugin({
        group: process.env.JSPEC_GROUP,
        nodeIndex: +process.env.CI_NODE_INDEX,
        nodeTotal: +process.env.CI_NODE_TOTAL,
      })
    ] : []
  )
}
