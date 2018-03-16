/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

module.exports = {
  transform: {
    '^.+\\.(js)$': 'babel-jest',
    '^.+\\.(css)$': '<rootDir>/jest-themeable-styles'
  },
  snapshotSerializers: [
    'enzyme-to-json/serializer'
  ],
  setupFiles: [
    './jest-env.js'
  ],
  testPathIgnorePatterns: [
    "<rootDir>/node_modues",
    "<rootDir>/lib",
    "<rootDir>/copy-of-what-gets-published-to-npm-registry",
  ],
  testRegex: "/__tests__/.*\\.(test|spec)\\.js$",
  coverageReporters: [
    'html',
    'text'
  ],
  collectCoverageFrom: [
    'src/**/*.js'
  ],
  coveragePathIgnorePatterns: [
    '<rootDir>/src/demo.js',
    '<rootDir>/src/i18n/flip-message.js'
  ],
  coverageThreshold: {
    global: {
      branches: 85,
      functions: 90,
      lines: 90,
      statements: 90
    }
  }
};
