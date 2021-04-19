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
  setupFiles: ['jest-canvas-mock', '<rootDir>/jest/jest-setup.js'],
  reporters: ['default', ['jest-junit', {outputDirectory: './coverage'}]],
  setupFilesAfterEnv: ['<rootDir>/jest/jest-setup-framework.js'],
  testPathIgnorePatterns: ['<rootDir>/node_modules', '<rootDir>/lib', '<rootDir>/canvas'],
  testMatch: ['**/__tests__/**/?(*.)(spec|test).js'],
  modulePathIgnorePatterns: ['<rootDir>/lib', '<rootDir>/canvas'],
  testEnvironment: 'jest-environment-jsdom-fourteen'
}
