/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

// eslint-disable-next-line import/no-unresolved
import {defineWorkspace} from 'vitest/config'

// Explicitly define workspace to prevent auto-detection of package configs
// Only run tests from the root vitest.config.ts (ui/ directory tests)
export default defineWorkspace([
  {
    extends: './vitest.config.ts',
    test: {
      name: 'canvas-ui',
      // Ensure we only run tests from ui/ directory
      include: ['ui/**/__tests__/**/*.test.?(c|m)[jt]s?(x)'],
      // Explicitly exclude packages, gems, and node_modules
      exclude: ['**/node_modules/**', 'packages/**', 'gems/**'],
    },
  },
])
