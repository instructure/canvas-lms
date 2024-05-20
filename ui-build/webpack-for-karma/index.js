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
const {DefinePlugin, EnvironmentPlugin, ProvidePlugin} = require('webpack')
const partitioning = require('./partitioning')
const PluginSpecsRunner = require('./PluginSpecsRunner')
const {canvasDir} = require('../params')

const {
  CONTEXT_COFFEESCRIPT_SPEC,
  CONTEXT_EMBER_GRADEBOOK_SPEC,
  CONTEXT_JSX_SPEC,
  RESOURCE_COFFEESCRIPT_SPEC,
  RESOURCE_EMBER_GRADEBOOK_SPEC,
  RESOURCE_JSX_SPEC,
} = partitioning

const WEBPACK_PLUGIN_SPECS = path.join(canvasDir, 'tmp/webpack-plugin-specs.js')

module.exports = {
  mode: 'development',
  module: {
    noParse: [require.resolve('jquery'), require.resolve('tinymce')],
    rules: [
      {
        test: /\.(mjs|js|jsx|ts|tsx)$/,
        type: 'javascript/auto',
        include: [path.resolve(canvasDir, 'node_modules/graphql')],
        resolve: {
          fullySpecified: false,
        },
      },
      {
        test: /\.(js|jsx|ts|tsx)$/,
        type: 'javascript/auto',
        include: [path.resolve(canvasDir, 'node_modules/@instructure')],
      },
      {
        test: /\.(js|jsx|ts|tsx)$/,
        include: [
          path.join(canvasDir, 'ui'),
          path.join(canvasDir, 'spec/javascripts/jsx'),
          path.join(canvasDir, 'spec/coffeescripts'),
          /gems\/plugins\/.*\/app\/(jsx|coffeescripts)\//,
        ],
        exclude: [/node_modules/],
        parser: {
          requireInclude: 'allow',
        },
        use: {
          loader: 'babel-loader',
          options: {
            cacheDirectory: false,
            configFile: false,
            presets: [
              ['@babel/preset-env'],
              ['@babel/preset-react', {useBuiltIns: true}],
              ['@babel/preset-typescript'],
            ],
            plugins: [
              // we need to have babel transpile ESM to CJS and can't just let
              // Webpack do it because Sinon is evidently no longer compatible
              // with the way Webpack 4 does CJS in as far as spying on module
              // symbols is concerned
              '@babel/plugin-transform-modules-commonjs',
              '@babel/plugin-proposal-optional-chaining',
              '@babel/plugin-proposal-class-properties',
            ],
          },
        },
      },
      {
        test: /\.handlebars$/,
        include: [path.join(canvasDir, 'ui'), /gems\/plugins\/.*\/app\/views\/jst\//],
        use: [
          {
            loader: require.resolve('#webpack-i18nliner-handlebars-loader'),
            options: {
              // brandable_css assets are not available in test
              injectBrandableStylesheet: false,
            },
          },
        ],
      },
      {
        test: /\.hbs$/,
        include: [path.join(canvasDir, 'ui/features/screenreader_gradebook/jst')],
        use: [require.resolve('#webpack-ember-handlebars-loader')],
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.(png|svg|gif)$/,
        loader: 'file-loader',
      },
      {
        test: /\.(woff(2)?|otf|ttf|eot)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        use: 'file-loader',
      },

      // Our spec files expect qunit's global `test`, `module`, `asyncTest` and
      // `start` variables. These imports loaders make it so they are avalable
      // as local variables inside of a closure, without truly making them
      // globals. We should get rid of this and just change our actual source to
      // s/test/qunit.test/ and s/module/qunit.module/
      {
        test: /\.(js|jsx|ts|tsx)$/,
        include: [
          path.join(canvasDir, 'spec/coffeescripts'),
          path.join(canvasDir, 'spec/javascripts/jsx'),
        ].concat(
          glob.sync('gems/plugins/*/spec_canvas/coffeescripts/', {
            cwd: canvasDir,
            absolute: true,
          })
        ),

        use: ['imports-loader?test=>QUnit.test'],
      },
    ],
  },
  resolve: {
    alias: {
      'node_modules-version-of-backbone$': require.resolve('backbone'),
      'node_modules-version-of-react-modal$': require.resolve('react-modal'),
      'spec/jsx': path.join(canvasDir, 'spec/javascripts/jsx'),
      'ui/boot/initializers': path.join(canvasDir, 'ui/boot/initializers'),
      'ui/ext': path.join(canvasDir, 'ui/ext'),
      'ui/features': path.join(canvasDir, 'ui/features'),
      [CONTEXT_COFFEESCRIPT_SPEC]: path.join(canvasDir, CONTEXT_COFFEESCRIPT_SPEC),
      [CONTEXT_EMBER_GRADEBOOK_SPEC]: path.join(canvasDir, CONTEXT_EMBER_GRADEBOOK_SPEC),
      [CONTEXT_JSX_SPEC]: path.join(canvasDir, CONTEXT_JSX_SPEC),

      // need to explicitly point this out for whatwg-url otherwise you get an
      // error like:
      //
      //     TypeError: Cannot read properties of undefined (reading 'decode')
      //
      // I suspect it's trying to use node's native impl and that doesn't work
      // when run through webpack
      punycode: path.join(canvasDir, 'node_modules/punycode/punycode.js'),
    },
    fallback: {
      path: false, // for minimatch
      stream: require.resolve('stream-browserify'),
    },
    extensions: ['.mjs', '.js', '.jsx', '.ts', '.tsx'],
    modules: [
      path.join(canvasDir, 'public/javascripts'),
      path.join(canvasDir, 'gems/plugins'),
      path.join(canvasDir, 'spec/coffeescripts'),
      'node_modules',
    ],
  },

  resolveLoader: {
    modules: ['node_modules', path.resolve(__dirname, '../webpack')],
  },

  plugins: [
    new DefinePlugin({
      CONTEXT_COFFEESCRIPT_SPEC: JSON.stringify(CONTEXT_COFFEESCRIPT_SPEC),
      CONTEXT_EMBER_GRADEBOOK_SPEC: JSON.stringify(CONTEXT_EMBER_GRADEBOOK_SPEC),
      CONTEXT_JSX_SPEC: JSON.stringify(CONTEXT_JSX_SPEC),
      RESOURCE_COFFEESCRIPT_SPEC,
      RESOURCE_EMBER_GRADEBOOK_SPEC,
      RESOURCE_JSX_SPEC,
      WEBPACK_PLUGIN_SPECS: JSON.stringify(WEBPACK_PLUGIN_SPECS),
      process: {browser: true, env: {}},
    }),

    new EnvironmentPlugin({
      JSPEC_PATH: null,
      JSPEC_GROUP: null,
      JSPEC_RECURSE: '1',
      JSPEC_VERBOSE: '0',
      A11Y_REPORT: false,
      GIT_COMMIT: null,
    }),

    new PluginSpecsRunner({
      pattern: 'gems/plugins/*/spec_canvas/coffeescripts/**/*Spec.js',
      outfile: WEBPACK_PLUGIN_SPECS,
    }),

    // needed for modules that expect Buffer to be present like fetch-mock (or
    // whatwg-url, its dependency)
    new ProvidePlugin({
      Buffer: ['buffer', 'Buffer'],
      $: 'jquery',
      jQuery: 'jquery',
      'window.jQuery': 'jquery',
    }),
  ].concat(
    process.env.JSPEC_GROUP
      ? [
          partitioning.createPlugin({
            group: process.env.JSPEC_GROUP,
            nodeIndex: +process.env.CI_NODE_INDEX,
            nodeTotal: +process.env.CI_NODE_TOTAL,
          }),
        ]
      : []
  ),
}
