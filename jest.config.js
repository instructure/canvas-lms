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
    '\\.svg$': '<rootDir>/jest/imageMock.js',
    'node_modules-version-of-backbone': require.resolve('backbone'),
    'node_modules-version-of-react-modal': require.resolve('react-modal'),
    '^Backbone$': '<rootDir>/public/javascripts/Backbone.js'
  },
  roots: ['ui', 'gems/plugins', 'public/javascripts'],
  moduleDirectories: ['ui/shims', 'public/javascripts', 'node_modules'],
  reporters: ['default', 'jest-junit'],
  snapshotSerializers: ['enzyme-to-json/serializer'],
  setupFiles: ['jest-localstorage-mock', 'jest-canvas-mock', '<rootDir>/jest/jest-setup.js'],
  setupFilesAfterEnv: [
    '@testing-library/jest-dom/extend-expect',
    './packages/validated-apollo/src/ValidatedApolloCleanup.js'
  ],
  testMatch: ['**/__tests__/**/?(*.)(spec|test).js'],

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
  }
}
