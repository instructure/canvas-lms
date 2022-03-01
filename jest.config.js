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

const {defaults} = require('jest-config')

module.exports = {
  moduleNameMapper: {
    '\\.svg$': '<rootDir>/jest/imageMock.js',
    'node_modules-version-of-backbone': require.resolve('backbone'),
    'node_modules-version-of-react-modal': require.resolve('react-modal'),
    '^Backbone$': '<rootDir>/public/javascripts/Backbone.js',
    // jest can't import the icons
    '@instructure/ui-icons/es/svg': '<rootDir>/packages/canvas-rce/src/rce/__tests__/_mockIcons.js',
    // redirect imports from es/rce to lib
    '@instructure/canvas-rce/es/rce/tinyRCE': '<rootDir>/packages/canvas-rce/lib/rce/tinyRCE.js',
    '@instructure/canvas-rce/es/rce/RCE': '<rootDir>/packages/canvas-rce/lib/rce/RCE.js',
    '@instructure/canvas-rce/es/rce/plugins/shared/Upload/CategoryProcessor':
      '<rootDir>/packages/canvas-rce/lib/rce/plugins/shared/Upload/CategoryProcessor',
    // mock the tinymce-react Editor react component
    '@tinymce/tinymce-react': '<rootDir>/packages/canvas-rce/src/rce/__mocks__/tinymceReact.js',
    'decimal.js/decimal.mjs': 'decimal.js/decimal.js'
  },
  roots: ['<rootDir>/ui', 'gems/plugins', 'public/javascripts'],
  moduleDirectories: ['ui/shims', 'public/javascripts', 'node_modules'],
  reporters: [
    'default',
    [
      'jest-junit',
      {
        suiteName: 'Jest Tests',
        outputDirectory: process.env.TEST_RESULT_OUTPUT_DIR || './coverage-js/junit-reports',
        outputName: 'jest.xml',
        addFileAttribute: 'true'
      }
    ]
  ],
  snapshotSerializers: ['enzyme-to-json/serializer'],
  setupFiles: ['jest-localstorage-mock', 'jest-canvas-mock', '<rootDir>/jest/jest-setup.js'],
  setupFilesAfterEnv: [
    '@testing-library/jest-dom/extend-expect',
    './packages/validated-apollo/src/ValidatedApolloCleanup.js'
  ],
  testMatch: ['**/__tests__/**/?(*.)(spec|test).[jt]s?(x)'],

  coverageDirectory: '<rootDir>/coverage-jest/',

  moduleFileExtensions: [...defaults.moduleFileExtensions, 'coffee', 'handlebars'],
  restoreMocks: true,

  testEnvironment: 'jest-environment-jsdom-fourteen',

  testSequencer: '<rootDir>/jest/test-sequencer.js',

  transform: {
    '\\.coffee$': '<rootDir>/jest/coffeeTransformer.js',
    '\\.handlebars$': '<rootDir>/jest/handlebarsTransformer.js',
    '\\.graphql$': 'jest-raw-loader',
    '\\.[jt]sx?$': [
      'babel-jest',
      {
        configFile: false,
        presets: [
          [
            '@babel/preset-env',
            {
              // until we're on Jest 27 and can look into loading ESMs natively;
              // https://jestjs.io/docs/ecmascript-modules
              modules: 'commonjs'
            }
          ],
          ['@babel/preset-react', {useBuiltIns: true}],
          ['@babel/preset-typescript', {}]
        ],
        targets: {
          node: 'current'
        }
      }
    ]
  }
}
