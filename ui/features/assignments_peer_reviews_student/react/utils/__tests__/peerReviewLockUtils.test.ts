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

import {getPeerReviewUnlockDate, isPeerReviewLocked} from '../peerReviewLockUtils'
import {Assignment} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

describe('peerReviewLockUtils', () => {
  const mockAssignment = (overrides = {}): Assignment => ({
    _id: '1',
    name: 'Test Assignment',
    dueAt: null,
    description: null,
    expectsSubmission: true,
    nonDigitalSubmission: false,
    pointsPossible: 10,
    courseId: '1',
    peerReviews: {count: 2, submissionRequired: true, pointsPossible: null},
    submissionsConnection: null,
    assignedToDates: null,
    assessmentRequestsForCurrentUser: null,
    ...overrides,
  })

  describe('getPeerReviewUnlockDate', () => {
    it('returns null when assignedToDates is null', () => {
      const assignment = mockAssignment()
      expect(getPeerReviewUnlockDate(assignment)).toBeNull()
    })

    it('returns assignment due date when peerReviewDates is null', () => {
      const dueDate = '2020-10-15T16:00:00Z'
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: dueDate,
            peerReviewDates: null,
          },
        ],
      })
      expect(getPeerReviewUnlockDate(assignment)).toBe(dueDate)
    })

    it('returns peer review unlock date when it is set', () => {
      const unlockDate = '2020-10-15T16:00:00Z'
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: '2020-10-10T16:00:00Z',
            peerReviewDates: {
              unlockAt: unlockDate,
              dueAt: null,
              lockAt: null,
            },
          },
        ],
      })
      expect(getPeerReviewUnlockDate(assignment)).toBe(unlockDate)
    })

    it('returns assignment due date when peer review unlock date is not set', () => {
      const dueDate = '2020-10-10T16:00:00Z'
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: dueDate,
            peerReviewDates: {
              unlockAt: null,
              dueAt: null,
              lockAt: null,
            },
          },
        ],
      })
      expect(getPeerReviewUnlockDate(assignment)).toBe(dueDate)
    })
  })

  describe('isPeerReviewLocked', () => {
    beforeEach(() => {
      // Mock the current date to 2020-10-01
      jest.useFakeTimers()
      jest.setSystemTime(new Date('2020-10-01T12:00:00Z'))
    })

    afterEach(() => {
      jest.useRealTimers()
    })

    it('returns false when assignedToDates is null', () => {
      const assignment = mockAssignment()
      expect(isPeerReviewLocked(assignment)).toBe(false)
    })

    it('returns false when unlock date is null', () => {
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: null,
            peerReviewDates: null,
          },
        ],
      })
      expect(isPeerReviewLocked(assignment)).toBe(false)
    })

    it('returns true when current time is before assignment due date', () => {
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: '2020-10-20T16:00:00Z',
            peerReviewDates: null,
          },
        ],
      })
      expect(isPeerReviewLocked(assignment)).toBe(true)
    })

    it('returns false when current time is after assignment due date', () => {
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: '2020-09-20T16:00:00Z',
            peerReviewDates: null,
          },
        ],
      })
      expect(isPeerReviewLocked(assignment)).toBe(false)
    })

    it('returns true when current time is before peer review unlock date', () => {
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: '2020-09-20T16:00:00Z',
            peerReviewDates: {
              unlockAt: '2020-10-31T06:00:00Z',
              dueAt: null,
              lockAt: null,
            },
          },
        ],
      })
      expect(isPeerReviewLocked(assignment)).toBe(true)
    })

    it('returns false when current time is after peer review unlock date', () => {
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: '2020-09-20T16:00:00Z',
            peerReviewDates: {
              unlockAt: '2020-09-30T06:00:00Z',
              dueAt: null,
              lockAt: null,
            },
          },
        ],
      })
      expect(isPeerReviewLocked(assignment)).toBe(false)
    })

    it('uses assignment due date when peer review unlock date is not set', () => {
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: '2020-10-20T16:00:00Z',
            peerReviewDates: {
              unlockAt: null,
              dueAt: null,
              lockAt: null,
            },
          },
        ],
      })
      expect(isPeerReviewLocked(assignment)).toBe(true)
    })
  })
})
