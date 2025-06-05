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
const {swc} = require('./ui-build/webpack/webpack.rules')

const esModules = ['mime', 'react-dnd', 'dnd-core', '@react-dnd', 'graphql-request'].join('|')

const baseSetupFilesAfterEnv = ['<rootDir>/jest/stubInstUi.js', '@testing-library/jest-dom']
const setupFilesAfterEnv = process.env.LOG_PLAYGROUND_URL_ON_FAILURE
  ? baseSetupFilesAfterEnv.concat(['<rootDir>/jest/logPlaygroundURLOnFailure.js'])
  : baseSetupFilesAfterEnv

module.exports = {
  randomize: true,
  testRunner: process.env.LOG_PLAYGROUND_URL_ON_FAILURE && 'jest-circus/runner',
  moduleNameMapper: {
    '\\.svg$': '<rootDir>/jest/imageMock.js',
    'node_modules-version-of-backbone': require.resolve('backbone'),
    'node_modules-version-of-react-modal': require.resolve('react-modal'),
    '^Backbone$': '<rootDir>/public/javascripts/Backbone.js',
    // jest can't import the icons
    '@instructure/ui-icons/es/svg': '<rootDir>/packages/canvas-rce/src/rce/__tests__/_mockIcons.js',
    // mock the tinymce-react Editor react component
    '@tinymce/tinymce-react': '<rootDir>/packages/canvas-rce/src/rce/__mocks__/tinymceReact.jsx',
    'decimal.js/decimal.mjs': 'decimal.js/decimal.js',
    // https://github.com/ai/nanoid/issues/363
    '^nanoid(/(.*)|$)': 'nanoid$1',
    '\\.(css)$': '<rootDir>/jest/styleMock.js',
    'crypto-es': '<rootDir>/packages/canvas-rce/src/rce/__mocks__/_mockCryptoEs.ts',
    '@instructure/studio-player':
      '<rootDir>/packages/canvas-rce/src/rce/__mocks__/_mockStudioPlayer.js',
  },
  roots: ['<rootDir>/ui', 'public/javascripts'],
  moduleDirectories: ['public/javascripts', 'node_modules'],
  reporters: [
    'default',
    [
      'jest-junit',
      {
        suiteName: 'Jest Tests',
        outputDirectory: process.env.TEST_RESULT_OUTPUT_DIR || './coverage-js/junit-reports',
        outputName: 'jest.xml',
        addFileAttribute: 'true',
        stripAnsi: true,
      },
    ],
  ],
  setupFiles: [
    'jest-localstorage-mock',
    'jest-canvas-mock',
    '<rootDir>/jest/jest-setup.js',
    '<rootDir>/jest/punycodeWarningFilter.js',
  ],
  setupFilesAfterEnv: setupFilesAfterEnv,
  testMatch: ['**/__tests__/**/?(*.)(spec|test).[jt]s?(x)'],

  coverageDirectory: '<rootDir>/coverage-jest/',

  // skip flaky timeout tests from coverage until they can be addressed
  // Related JIRA tickets for the skipped coverage tests;
  // k5_dashboard: LS-2243
  collectCoverageFrom: [
    '**/__tests__/**/?(*.)(spec|test).[jt]s?(x)',
    '!<rootDir>/ui/features/k5_dashboard/react/__tests__/k5DashboardPlanner.test.js',
  ],

  moduleFileExtensions: [...defaults.moduleFileExtensions, 'coffee', 'handlebars'],
  restoreMocks: true,

  testEnvironment: process.env.LOG_PLAYGROUND_URL_ON_FAILURE
    ? '<rootDir>/jest/environmentWrapper.js'
    : 'jest-fixed-jsdom',

  transformIgnorePatterns: [`/node_modules/(?!${esModules})`],

  transform: {
    '\\.handlebars$': '<rootDir>/jest/handlebarsTransformer.js',
    '\\.graphql$': '<rootDir>/jest/rawLoader.js',
    '^.+\\.(j|t)s?$': [
      '@swc/jest',
      {
        jsc: swc[0].use.options.jsc,
      },
    ],
    '^.+\\.(j|t)sx?$': [
      '@swc/jest',
      {
        jsc: {
          ...swc[1].use.options.jsc,
          transform: {
            ...swc[1].use.options.jsc.transform,
            react: {
              ...swc[1].use.options.jsc.transform.react,
              runtime: 'automatic',
              // These are `process.env.NODE_ENV === 'development'` in the webpack config
              // but Jest doesn't set that env var until after this file is loaded, so
              // we need to set it manually here.
              development: false,
              refresh: false,
            },
          },
        },
      },
    ],
  },
  extensionsToTreatAsEsm: ['.jsx'],
  testEnvironmentOptions: {
    // https://github.com/mswjs/examples/blob/main/examples/with-jest/jest.config.ts#L20
    customExportConditions: [''],
  },
  testTimeout: 10000,
}
