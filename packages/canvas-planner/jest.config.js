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
    '^.+\\.(js)$': ['babel-jest', { configFile: require.resolve('./babel.config.cjs.js') }],
    '^.+\\.(css)$': '<rootDir>/jest-themeable-styles'
  },
  reporters: [
    'default',
    [
      'jest-junit',
      {
        suiteName: 'Canvas Planner Jest Tests',
        outputDirectory: process.env.TEST_RESULT_OUTPUT_DIR || './coverage',
        outputName: 'canvas-planner-junit.xml'
      }
    ]
  ],
  snapshotSerializers: ['enzyme-to-json/serializer'],
  setupFiles: ['jest-canvas-mock', './jest-env.js'],
  setupFilesAfterEnv: ['@testing-library/jest-dom/extend-expect'],
  testPathIgnorePatterns: ['<rootDir>/node_modules', '<rootDir>/lib'],
  testRegex: '/__tests__/.*\\.(test|spec)\\.js$',
  coverageReporters: ['html', 'text', 'json'],
  collectCoverageFrom: ['src/**/*.js'],
  coveragePathIgnorePatterns: ['<rootDir>/src/i18n/flip-message.js'],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  testEnvironment: 'jsdom'
}
