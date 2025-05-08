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

import {
  allAreEqual,
  defaultDate,
  defaultDateRangeType,
  isStartDateRequired,
  isEndDateRequired,
  DATE_RANGE_TYPE_OPTIONS,
} from '../PermissionsModalUtils'
import {FAKE_FILES} from '../../../../../fixtures/fakeData'

describe('PermissionsModalUtils', () => {
  describe('allAreEqual', () => {
    it('returns true when items array length is 0', () => {
      const result = allAreEqual([], ['hidden'])
      expect(result).toBe(true)
    })

    it('returns true when items array length is 1', () => {
      const result = allAreEqual([FAKE_FILES[0]], ['hidden'])
      expect(result).toBe(true)
    })

    it('returns true when items array attributes are the same', () => {
      const result = allAreEqual(
        [
          {
            ...FAKE_FILES[0],
            lock_at: '2025-01-01T00:00:00Z',
            unlock_at: '2025-01-02T00:00:00Z',
          },
          {
            ...FAKE_FILES[1],
            lock_at: '2025-01-01T00:00:00Z',
            unlock_at: '2025-01-02T00:00:00Z',
          },
        ],
        ['lock_at', 'unlock_at'],
      )
      expect(result).toBe(true)
    })

    it('returns false when items array attributes are not the same', () => {
      const result = allAreEqual(
        [
          {
            ...FAKE_FILES[0],
            lock_at: '2025-01-01T00:00:00Z',
            unlock_at: '2025-01-02T00:00:00Z',
          },
          {
            ...FAKE_FILES[1],
            lock_at: '2025-01-01T00:00:00Z',
            unlock_at: null,
          },
        ],
        ['lock_at', 'unlock_at'],
      )
      expect(result).toBe(false)
    })
  })

  describe('defaultDate', () => {
    it('returns null when array is empty', () => {
      const result = defaultDate([], 'unlock_at')
      expect(result).toBe(null)
    })

    it('returns null when lock_at and unlock_at are null', () => {
      const result = defaultDate(
        [
          {
            ...FAKE_FILES[0],
            lock_at: null,
            unlock_at: null,
          },
        ],
        'unlock_at',
      )
      expect(result).toBe(null)
    })

    it('returns unlock_at when unlock_at is not null', () => {
      const result = defaultDate(
        [
          {
            ...FAKE_FILES[0],
            lock_at: null,
            unlock_at: '2025-01-01T00:00:00Z',
          },
        ],
        'unlock_at',
      )
      expect(result).toBe('2025-01-01T00:00:00Z')
    })

    it('returns lock_at when lock_at is not null', () => {
      const result = defaultDate(
        [
          {
            ...FAKE_FILES[0],
            lock_at: '2025-01-01T00:00:00Z',
            unlock_at: null,
          },
        ],
        'lock_at',
      )
      expect(result).toBe('2025-01-01T00:00:00Z')
    })

    it('returns unlock at when both has the same permission values', () => {
      const result = defaultDate(
        [
          {
            ...FAKE_FILES[0],
            lock_at: '2025-01-01T00:00:00Z',
            unlock_at: '2025-01-01T00:00:00Z',
            hidden: false,
            locked: false,
          },
          {
            ...FAKE_FILES[1],
            hidden: false,
            locked: false,
            lock_at: '2025-01-01T00:00:00Z',
            unlock_at: '2025-01-01T00:00:00Z',
          },
        ],
        'lock_at',
      )
      expect(result).toBe('2025-01-01T00:00:00Z')
    })

    it('returns null when both have different permission values', () => {
      const result = defaultDate(
        [
          {
            ...FAKE_FILES[0],
            lock_at: '2025-01-01T00:00:00Z',
            unlock_at: '2025-01-01T00:00:00Z',
            hidden: false,
            locked: false,
          },
          {
            ...FAKE_FILES[1],
            hidden: true,
            locked: true,
            lock_at: '2025-01-01T00:00:00Z',
            unlock_at: '2025-01-01T00:00:00Z',
          },
        ],
        'lock_at',
      )
      expect(result).toBe(null)
    })
  })

  describe('defaultDateRangeType', () => {
    it('returns null when array is empty', () => {
      const result = defaultDateRangeType([])
      expect(result).toBe(null)
    })

    it('returns null when lock_at and unlock_at are null', () => {
      const result = defaultDateRangeType([
        {
          ...FAKE_FILES[0],
          lock_at: null,
          unlock_at: null,
        },
      ])
      expect(result).toBe(null)
    })

    it('returns start when lock_at is null and unlock_at is not null', () => {
      const result = defaultDateRangeType([
        {
          ...FAKE_FILES[0],
          lock_at: null,
          unlock_at: '2025-01-01T00:00:00Z',
        },
      ])
      expect(result).toBe(DATE_RANGE_TYPE_OPTIONS.start)
    })

    it('returns end when lock_at is not null and unlock_at is null', () => {
      const result = defaultDateRangeType([
        {
          ...FAKE_FILES[0],
          lock_at: '2025-01-01T00:00:00Z',
          unlock_at: null,
        },
      ])
      expect(result).toBe(DATE_RANGE_TYPE_OPTIONS.end)
    })

    it('returns range when lock_at and unlock_at are not null', () => {
      const result = defaultDateRangeType([
        {
          ...FAKE_FILES[0],
          lock_at: '2025-01-01T00:00:00Z',
          unlock_at: '2025-01-02T00:00:00Z',
        },
      ])
      expect(result).toBe(DATE_RANGE_TYPE_OPTIONS.range)
    })
  })

  it('returns null when permissions fields are different', () => {
    const result = defaultDateRangeType([
      {
        ...FAKE_FILES[0],
        lock_at: '2025-01-01T00:00:00Z',
        unlock_at: '2025-01-02T00:00:00Z',
      },
      {
        ...FAKE_FILES[1],
        lock_at: null,
        unlock_at: null,
      },
    ])
    expect(result).toBe(null)
  })

  describe('isStartDateRequired', () => {
    it('returns false when dateRangeType is null', () => {
      const result = isStartDateRequired(null)
      expect(result).toBe(false)
    })

    it('returns false when dateRangeType is end', () => {
      const result = isStartDateRequired(DATE_RANGE_TYPE_OPTIONS.end)
      expect(result).toBe(false)
    })

    it('returns true when dateRangeType is start', () => {
      const result = isStartDateRequired(DATE_RANGE_TYPE_OPTIONS.start)
      expect(result).toBe(true)
    })

    it('returns true when dateRangeType is range', () => {
      const result = isStartDateRequired(DATE_RANGE_TYPE_OPTIONS.range)
      expect(result).toBe(true)
    })
  })

  describe('isEndDateRequired', () => {
    it('returns false when dateRangeType is null', () => {
      const result = isEndDateRequired(null)
      expect(result).toBe(false)
    })

    it('returns false when dateRangeType is start', () => {
      const result = isEndDateRequired(DATE_RANGE_TYPE_OPTIONS.start)
      expect(result).toBe(false)
    })

    it('returns true when dateRangeType is end', () => {
      const result = isEndDateRequired(DATE_RANGE_TYPE_OPTIONS.end)
      expect(result).toBe(true)
    })

    it('returns true when dateRangeType is range', () => {
      const result = isEndDateRequired(DATE_RANGE_TYPE_OPTIONS.range)
      expect(result).toBe(true)
    })
  })
})
