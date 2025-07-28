/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {parseDateToISOString} from '../utils'

describe('parseDateToISOString', () => {
  it('returns an empty string for null date string', () => {
    expect(parseDateToISOString(null)).toBeNull()
  })

  it('returns an empty string for undefined date string', () => {
    expect(parseDateToISOString(undefined)).toBeNull()
  })

  it('returns an empty string for invalid date string', () => {
    expect(parseDateToISOString('invalid date')).toBeNull()
  })

  it('returns ISO string for valid date string', () => {
    const date = '2023-01-01'
    expect(parseDateToISOString(date)).toBe('2023-01-01T00:00:00.000Z')
  })

  it('returns ISO string for valid date', () => {
    const date = new Date('2023-01-01T00:00:00Z')
    expect(parseDateToISOString(date)).toBe(date.toISOString())
  })
})
