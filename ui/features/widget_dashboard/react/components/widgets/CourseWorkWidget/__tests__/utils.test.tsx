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

import {getSubmissionStatus, formatDueDate} from '../utils'

describe('CourseWorkWidget utils', () => {
  describe('getSubmissionStatus', () => {
    it('returns missing status when missing is true', () => {
      const status = getSubmissionStatus(false, true, 'unsubmitted', null)
      expect(status.type).toBe('missing')
      expect(status.label).toBe('Missing')
    })

    it('returns late status when late is true', () => {
      const status = getSubmissionStatus(true, false, 'submitted', null)
      expect(status.type).toBe('late')
      expect(status.label).toBe('Late')
    })

    it('returns submitted status when state is submitted', () => {
      const status = getSubmissionStatus(false, false, 'submitted', null)
      expect(status.type).toBe('submitted')
      expect(status.label).toBe('Submitted')
    })

    it('returns submitted status when state is graded', () => {
      const status = getSubmissionStatus(false, false, 'graded', null)
      expect(status.type).toBe('submitted')
      expect(status.label).toBe('Submitted')
    })

    it('returns pending review status when state is pending_review', () => {
      const status = getSubmissionStatus(false, false, 'pending_review', null)
      expect(status.type).toBe('pending_review')
      expect(status.label).toBe('Pending Review')
    })

    it('returns due soon status when due tomorrow', () => {
      const tomorrow = new Date()
      tomorrow.setDate(tomorrow.getDate() + 1)
      tomorrow.setHours(15, 30, 0, 0) // 3:30 PM
      const tomorrowDate = tomorrow.toISOString()

      const status = getSubmissionStatus(false, false, 'unsubmitted', tomorrowDate)
      expect(status.type).toBe('due_soon')
      expect(status.label).toBe('Tomorrow 3:30 PM')
    })

    it('returns not submitted status as default', () => {
      const status = getSubmissionStatus(false, false, 'unsubmitted', null)
      expect(status.type).toBe('not_submitted')
      expect(status.label).toBe('Not Submitted')
    })
  })

  describe('formatDueDate', () => {
    it('formats due date for today', () => {
      const today = new Date()
      today.setHours(15, 30, 0, 0) // 3:30 PM
      const todayISO = today.toISOString()

      const formatted = formatDueDate(todayISO)
      expect(formatted).toContain('Today')
      expect(formatted).toContain('3:30')
    })

    it('formats due date for tomorrow', () => {
      const tomorrow = new Date()
      tomorrow.setDate(tomorrow.getDate() + 1)
      tomorrow.setHours(14, 45, 0, 0) // 2:45 PM
      const tomorrowISO = tomorrow.toISOString()

      const formatted = formatDueDate(tomorrowISO)
      expect(formatted).toContain('Tomorrow')
      expect(formatted).toContain('2:45')
    })
  })
})
