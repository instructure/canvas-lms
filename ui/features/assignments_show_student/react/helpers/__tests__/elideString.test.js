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

import elideString from '../elideString'

describe('elideString', () => {
  it('elides filenames for files greater than 21 characters', () => {
    expect(elideString('c'.repeat(22))).toMatch(/^c+\.{3}c+$/)
  })

  it('does not elide filenames for files less than or equal to 21 characters', () => {
    const filename = 'c'.repeat(21)
    expect(elideString(filename)).toMatch(filename)
  })
})
