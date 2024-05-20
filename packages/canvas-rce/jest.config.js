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

// Used to enable babel transformations for node_modules that use ecmascript module syntax directly
// From https://github.com/nrwl/nx/issues/812
const esModules = ['text-field-edit', '@instructure\\/ui-icons'].join('|')

module.exports = {
  setupFiles: ['jest-canvas-mock', '<rootDir>/jest/jest-setup.js'],
  reporters: [
    'default',
    [
      'jest-junit',
      {
        suiteName: 'Canvas RCE Jest Tests',
        outputDirectory: process.env.TEST_RESULT_OUTPUT_DIR || './coverage',
        outputName: 'canvas-rce-jest.xml',
      },
    ],
  ],
  setupFilesAfterEnv: [
    '<rootDir>/jest/jest-setup-framework.js',
    '<rootDir>/../../jest/stubInstUi.js',
  ],
  testPathIgnorePatterns: ['<rootDir>/node_modules', '<rootDir>/canvas'],
  testMatch: ['**/__tests__/**/?(*.)(spec|test).[jt]s?(x)'],
  modulePathIgnorePatterns: ['<rootDir>/es', '<rootDir>/canvas'],
  transformIgnorePatterns: [`/node_modules/(?!${esModules})`],
  testEnvironment: '<rootDir>../../jest/strictTimeLimitEnvironment.js',
  moduleNameMapper: {
    // jest can't import css
    '\\.(css|less)$': '<rootDir>/src/rce/__mocks__/styleMock.js',
    // mock the tinymce-react Editor component
    '@tinymce/tinymce-react': '<rootDir>/src/rce/__mocks__/tinymceReact.jsx',
    'crypto-es': '<rootDir>/src/rce/__mocks__/_mockCryptoEs.ts',
  },

  transform: {
    '\\.[jt]sx?$': [
      'babel-jest',
      {
        configFile: false,
        presets: [
          ['@babel/preset-env'],
          ['@babel/preset-react', {}],
          ['@babel/preset-typescript', {}],
        ],
        plugins: [
          ['@babel/plugin-proposal-decorators', {legacy: true}],
        ],
      },
    ],
  },
}
