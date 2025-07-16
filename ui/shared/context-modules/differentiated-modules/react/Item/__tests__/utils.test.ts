/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {arrayEquals, setEquals, setSeconds} from '../utils'

describe('arrayEquals', () => {
  it('returns true for equal arrays', () => {
    expect(arrayEquals([1, 2, 3], [1, 2, 3])).toBe(true)
  })
  it('returns false for different arrays', () => {
    expect(arrayEquals([1, 2, 3], [1, 2, 4])).toBe(false)
    expect(arrayEquals([1, 2], [1, 2, 3])).toBe(false)
  })
})

describe('setEquals', () => {
  it('returns true for equal sets', () => {
    expect(setEquals(new Set([1, 2]), new Set([2, 1]))).toBe(true)
  })
  it('returns false for different sets', () => {
    expect(setEquals(new Set([1, 2]), new Set([1, 3]))).toBe(false)
    expect(setEquals(new Set([1]), new Set([1, 2]))).toBe(false)
  })
})

describe('setSeconds', () => {
  it('returns null if date is null', () => {
    expect(setSeconds(null as any)).toBeNull()
  })

  it('sets the seconds to 59 if the minute is 59', () => {
    const date = '2024-01-01T12:59:00Z'
    const result = setSeconds(date)
    expect(new Date(result!).getUTCSeconds()).toBe(59)
  })

  it('sets the seconds to 0 if the minute is not 59', () => {
    const date = '2024-01-01T12:30:00Z'
    const result = setSeconds(date)
    expect(new Date(result!).getUTCSeconds()).toBe(0)
  })
})
