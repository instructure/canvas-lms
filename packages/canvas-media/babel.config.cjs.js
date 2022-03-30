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

// this target is intended for Jest / JSDOM Node.js environments and is not
// suitable for the browser or production
module.exports = {
  presets: [
    ['@babel/preset-env', {
      modules: 'commonjs',
    }],
    ['@babel/preset-react', { useBuiltIns: true }],
  ],
  targets: {
    node: 'current'
  },
}
