/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
    '^i18n!(.*$)': '<rootDir>/jest/i18nTransformer.js',
    "\\.svg$": "<rootDir>/jest/imageMock.js",
    '^compiled/(.*)$': '<rootDir>/app/coffeescripts/$1',
    '^coffeescripts/(.*)$': '<rootDir>/app/coffeescripts/$1',
    '^jsx/(.*)$': '<rootDir>/app/jsx/$1',
    '^jst/(.*)$': '<rootDir>/app/views/jst/$1',
    "^timezone$": "<rootDir>/public/javascripts/timezone_core.js",
    'node_modules-version-of-backbone': require.resolve('backbone')
  },
  roots: ['app/jsx', 'app/coffeescripts', 'public/javascripts'],
  moduleDirectories: [
    'node_modules',
    'public/javascripts',
    'public/javascripts/vendor'
  ],
  reporters: [ "default", "jest-junit" ],
  snapshotSerializers: [
    'enzyme-to-json/serializer'
  ],
  setupFiles: [
    'jest-localstorage-mock',
    'jest-canvas-mock',
    '<rootDir>/jest/jest-setup.js'
  ],
  setupFilesAfterEnv: [
    '@testing-library/jest-dom/extend-expect',
    './app/jsx/__tests__/ValidatedApolloCleanup'
  ],
  testMatch: [
    '**/__tests__/**/?(*.)(spec|test).js'
  ],

  coverageDirectory: '<rootDir>/coverage-jest/',

  moduleFileExtensions: [...defaults.moduleFileExtensions, 'coffee', 'handlebars'],
  restoreMocks: true,

  testEnvironment: 'jest-environment-jsdom-fourteen',

  transform: {
    '^i18n': '<rootDir>/jest/i18nTransformer.js',
    '^.+\\.coffee': '<rootDir>/jest/coffeeTransformer.js',
    '^.+\\.handlebars': '<rootDir>/jest/handlebarsTransformer.js',
    '^.+\\.jsx?$': 'babel-jest',
    '\\.graphql$': 'jest-raw-loader'
  },
}
