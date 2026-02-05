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
  getPeerReviewUnlockDate,
  isPeerReviewLocked,
  getPeerReviewLockDate,
  isPeerReviewPastLockDate,
} from '../peerReviewLockUtils'
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
    peerReviews: {
      count: 2,
      submissionRequired: true,
      pointsPossible: null,
      anonymousReviews: false,
    },
    submissionsConnection: null,
    peerReviewSubAssignment: null,
    assessmentRequestsForCurrentUser: null,
    ...overrides,
  })

  describe('getPeerReviewUnlockDate', () => {
    it('returns null when peerReviewSubAssignment is null', () => {
      const assignment = mockAssignment()
      expect(getPeerReviewUnlockDate(assignment)).toBeNull()
    })

    it('returns assignment due date when peerReviewSubAssignment is null', () => {
      const dueDate = '2020-10-15T16:00:00Z'
      const assignment = mockAssignment({
        dueAt: dueDate,
        peerReviewSubAssignment: null,
      })
      expect(getPeerReviewUnlockDate(assignment)).toBe(dueDate)
    })

    it('returns peer review unlock date when it is set', () => {
      const unlockDate = '2020-10-15T16:00:00Z'
      const assignment = mockAssignment({
        dueAt: '2020-10-10T16:00:00Z',
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: unlockDate,
          lockAt: null,
        },
      })
      expect(getPeerReviewUnlockDate(assignment)).toBe(unlockDate)
    })

    it('returns assignment due date when peer review unlock date is not set', () => {
      const dueDate = '2020-10-10T16:00:00Z'
      const assignment = mockAssignment({
        dueAt: dueDate,
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: null,
          lockAt: null,
        },
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

    it('returns false when peerReviewSubAssignment is null', () => {
      const assignment = mockAssignment()
      expect(isPeerReviewLocked(assignment)).toBe(false)
    })

    it('returns false when unlock date is null', () => {
      const assignment = mockAssignment({
        dueAt: null,
        peerReviewSubAssignment: null,
      })
      expect(isPeerReviewLocked(assignment)).toBe(false)
    })

    it('returns true when current time is before assignment due date', () => {
      const assignment = mockAssignment({
        dueAt: '2020-10-20T16:00:00Z',
        peerReviewSubAssignment: null,
      })
      expect(isPeerReviewLocked(assignment)).toBe(true)
    })

    it('returns false when current time is after assignment due date', () => {
      const assignment = mockAssignment({
        dueAt: '2020-09-20T16:00:00Z',
        peerReviewSubAssignment: null,
      })
      expect(isPeerReviewLocked(assignment)).toBe(false)
    })

    it('returns true when current time is before peer review unlock date', () => {
      const assignment = mockAssignment({
        dueAt: '2020-09-20T16:00:00Z',
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: '2020-10-31T06:00:00Z',
          lockAt: null,
        },
      })
      expect(isPeerReviewLocked(assignment)).toBe(true)
    })

    it('returns false when current time is after peer review unlock date', () => {
      const assignment = mockAssignment({
        dueAt: '2020-09-20T16:00:00Z',
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: '2020-09-30T06:00:00Z',
          lockAt: null,
        },
      })
      expect(isPeerReviewLocked(assignment)).toBe(false)
    })

    it('uses assignment due date when peer review unlock date is not set', () => {
      const assignment = mockAssignment({
        dueAt: '2020-10-20T16:00:00Z',
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: null,
          lockAt: null,
        },
      })
      expect(isPeerReviewLocked(assignment)).toBe(true)
    })
  })

  describe('getPeerReviewLockDate', () => {
    it('returns null when peerReviewSubAssignment is null', () => {
      const assignment = mockAssignment()
      expect(getPeerReviewLockDate(assignment)).toBeNull()
    })

    it('returns null when peerReviewSubAssignment is null', () => {
      const assignment = mockAssignment({
        dueAt: '2020-10-15T16:00:00Z',
        peerReviewSubAssignment: null,
      })
      expect(getPeerReviewLockDate(assignment)).toBeNull()
    })

    it('returns peer review lock date when it is set', () => {
      const lockDate = '2020-10-31T18:00:00Z'
      const assignment = mockAssignment({
        dueAt: '2020-10-10T16:00:00Z',
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: '2020-10-15T16:00:00Z',
          lockAt: lockDate,
        },
      })
      expect(getPeerReviewLockDate(assignment)).toBe(lockDate)
    })

    it('returns null when peer review lock date is not set', () => {
      const assignment = mockAssignment({
        dueAt: '2020-10-10T16:00:00Z',
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: '2020-10-15T16:00:00Z',
          lockAt: null,
        },
      })
      expect(getPeerReviewLockDate(assignment)).toBeNull()
    })
  })

  describe('isPeerReviewPastLockDate', () => {
    beforeEach(() => {
      jest.useFakeTimers()
      jest.setSystemTime(new Date('2020-10-01T12:00:00Z'))
    })

    afterEach(() => {
      jest.useRealTimers()
    })

    it('returns false when peerReviewSubAssignment is null', () => {
      const assignment = mockAssignment()
      expect(isPeerReviewPastLockDate(assignment)).toBe(false)
    })

    it('returns false when lock date is null', () => {
      const assignment = mockAssignment({
        dueAt: '2020-10-10T16:00:00Z',
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: '2020-09-30T06:00:00Z',
          lockAt: null,
        },
      })
      expect(isPeerReviewPastLockDate(assignment)).toBe(false)
    })

    it('returns true when current time is after peer review lock date', () => {
      const assignment = mockAssignment({
        dueAt: '2020-10-10T16:00:00Z',
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: '2020-09-20T06:00:00Z',
          lockAt: '2020-09-30T18:00:00Z',
        },
      })
      expect(isPeerReviewPastLockDate(assignment)).toBe(true)
    })

    it('returns false when current time is before peer review lock date', () => {
      const assignment = mockAssignment({
        dueAt: '2020-10-10T16:00:00Z',
        peerReviewSubAssignment: {
          dueAt: null,
          unlockAt: '2020-09-20T06:00:00Z',
          lockAt: '2020-10-31T18:00:00Z',
        },
      })
      expect(isPeerReviewPastLockDate(assignment)).toBe(false)
    })

    it('returns false when peerReviewSubAssignment is null', () => {
      const assignment = mockAssignment({
        dueAt: '2020-10-10T16:00:00Z',
        peerReviewSubAssignment: null,
      })
      expect(isPeerReviewPastLockDate(assignment)).toBe(false)
    })
  })
})
