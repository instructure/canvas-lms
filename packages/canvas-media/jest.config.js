/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
  modulePathIgnorePatterns: ['<rootDir>/lib', '<rootDir>/es'],
  reporters: [
    'default',
    [
      'jest-junit',
      {
        suiteName: 'Canvas Media Jest Tests',
        outputDirectory: process.env.TEST_RESULT_OUTPUT_DIR || './coverage',
        outputName: 'canvas-media-junit.xml',
      },
    ],
  ],
  setupFiles: ['jest-canvas-mock', '<rootDir>/jest/jest-setup.js'],
  setupFilesAfterEnv: ['@testing-library/jest-dom/extend-expect'],
  testEnvironment: '<rootDir>../../jest/strictTimeLimitEnvironment.js',
  testMatch: ['**/__tests__/**/?(*.)(spec|test).[jt]s?(x)'],
  testPathIgnorePatterns: ['<rootDir>/node_modules', '<rootDir>/lib', '<rootDir>/es'],
  transform: {
    '\\.jsx?$': [
      'babel-jest',
      {
        // use the CJS config until we're on Jest 27 and can look into loading
        // ESMs natively; https://jestjs.io/docs/ecmascript-modules
        configFile: require.resolve('./babel.config.cjs.js'),
      },
    ],
  },
}
