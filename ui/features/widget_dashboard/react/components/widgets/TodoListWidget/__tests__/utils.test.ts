/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {formatAnnouncementDate, formatDate, getPlannableTypeLabel, isOverdue} from '../utils'

describe('utils', () => {
  describe('formatAnnouncementDate', () => {
    it('returns "Posted" with formatted date', () => {
      const result = formatAnnouncementDate('2026-01-22T18:00:00Z')
      expect(result).toMatch(/Posted.*Jan.*22.*2026/)
    })

    it('returns empty string for undefined', () => {
      expect(formatAnnouncementDate(undefined)).toBe('')
    })
  })

  describe('formatDate', () => {
    it('returns empty string for undefined', () => {
      expect(formatDate(undefined)).toBe('')
    })

    it('returns "Overdue" for past dates', () => {
      const pastDate = new Date()
      pastDate.setDate(pastDate.getDate() - 1)
      expect(formatDate(pastDate.toISOString())).toBe('Overdue')
    })

    it('returns "Due soon" for dates less than an hour away', () => {
      const soonDate = new Date()
      soonDate.setMinutes(soonDate.getMinutes() + 30)
      expect(formatDate(soonDate.toISOString())).toBe('Due soon')
    })
  })

  describe('getPlannableTypeLabel', () => {
    it('returns correct label for assignment', () => {
      expect(getPlannableTypeLabel('assignment')).toBe('Assignment')
    })

    it('returns correct label for announcement', () => {
      expect(getPlannableTypeLabel('announcement')).toBe('Announcement')
    })

    it('returns "Item" for unknown type', () => {
      expect(getPlannableTypeLabel('unknown' as any)).toBe('Item')
    })
  })

  describe('isOverdue', () => {
    it('returns false for undefined', () => {
      expect(isOverdue(undefined)).toBe(false)
    })

    it('returns true for past dates', () => {
      const pastDate = new Date()
      pastDate.setDate(pastDate.getDate() - 1)
      expect(isOverdue(pastDate.toISOString())).toBe(true)
    })

    it('returns false for future dates', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 1)
      expect(isOverdue(futureDate.toISOString())).toBe(false)
    })
  })
})
