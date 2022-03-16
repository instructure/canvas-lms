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
  setupFiles: ['jest-canvas-mock', '<rootDir>/jest/jest-setup.js'],
  reporters: [
    'default',
    [
      'jest-junit',
      {
        suiteName: 'Canvas RCE Jest Tests',
        outputDirectory: process.env.TEST_RESULT_OUTPUT_DIR || './coverage',
        outputName: 'canvas-rce-jest.xml'
      }
    ]
  ],
  setupFilesAfterEnv: ['<rootDir>/jest/jest-setup-framework.js'],
  testPathIgnorePatterns: ['<rootDir>/node_modules', '<rootDir>/lib', '<rootDir>/canvas'],
  testMatch: ['**/__tests__/**/?(*.)(spec|test).js'],
  modulePathIgnorePatterns: ['<rootDir>/es', '<rootDir>/lib', '<rootDir>/canvas'],
  testEnvironment: 'jest-environment-jsdom-fourteen',
  moduleNameMapper: {
    // jest can't import the icons
    '@instructure/ui-icons/es/svg': '<rootDir>/src/rce/__tests__/_mockIcons.js',
    // mock the tinymce-react Editor component
    '@tinymce/tinymce-react': '<rootDir>/src/rce/__mocks__/tinymceReact.js'
  },

  transform: {
    '\\.jsx?$': ['babel-jest', {
      configFile: false,
      presets: [
        ['@babel/preset-env'],
        ['@babel/preset-react', {}],
      ],
      plugins: [
        ['@babel/plugin-proposal-decorators', {legacy: true}],
        ['@instructure/babel-plugin-themeable-styles', {
          postcssrc: require('@instructure/ui-postcss-config')()(),
          themeablerc: {},
        }]
      ],
    }]
  }
}
