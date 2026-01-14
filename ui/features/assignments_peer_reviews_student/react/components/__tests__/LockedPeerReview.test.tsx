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

import React from 'react'
import {render, screen} from '@testing-library/react'
import LockedPeerReview from '../LockedPeerReview'
import {Assignment} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

describe('LockedPeerReview', () => {
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

  it('renders "Assignment is unavailable" when unlock date is null', () => {
    const assignment = mockAssignment()
    render(<LockedPeerReview assignment={assignment} />)
    expect(screen.getByTestId('locked-peer-review')).toBeInTheDocument()
    expect(screen.getByText('Assignment is unavailable.')).toBeInTheDocument()
  })

  it('renders locked message with unlock date', () => {
    const assignment = mockAssignment({
      assignedToDates: [
        {
          dueAt: '2020-10-20T16:00:00Z',
          peerReviewDates: null,
        },
      ],
    })
    render(<LockedPeerReview assignment={assignment} />)
    expect(screen.getByTestId('locked-peer-review')).toBeInTheDocument()
    expect(screen.getByText(/This assignment is locked until/)).toBeInTheDocument()
  })

  it('renders locked message with peer review unlock date', () => {
    const assignment = mockAssignment({
      assignedToDates: [
        {
          dueAt: '2020-10-10T16:00:00Z',
          peerReviewDates: {
            unlockAt: '2020-10-31T06:00:00Z',
            dueAt: null,
            lockAt: null,
          },
        },
      ],
    })
    render(<LockedPeerReview assignment={assignment} />)
    expect(screen.getByTestId('locked-peer-review')).toBeInTheDocument()
    expect(screen.getByText(/This assignment is locked until/)).toBeInTheDocument()
  })

  describe('Past lock date', () => {
    it('renders "no longer available" message when isPastLockDate is true', () => {
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: '2020-10-10T16:00:00Z',
            peerReviewDates: {
              unlockAt: '2020-09-20T06:00:00Z',
              dueAt: null,
              lockAt: '2020-09-30T18:00:00Z',
            },
          },
        ],
      })
      render(<LockedPeerReview assignment={assignment} isPastLockDate={true} />)
      expect(screen.getByTestId('locked-peer-review')).toBeInTheDocument()
      expect(screen.getByText(/This assignment is no longer available as of/)).toBeInTheDocument()
    })

    it('renders "locked until" message when isPastLockDate is false', () => {
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: '2020-10-10T16:00:00Z',
            peerReviewDates: {
              unlockAt: '2020-10-31T06:00:00Z',
              dueAt: null,
              lockAt: '2020-11-30T18:00:00Z',
            },
          },
        ],
      })
      render(<LockedPeerReview assignment={assignment} isPastLockDate={false} />)
      expect(screen.getByTestId('locked-peer-review')).toBeInTheDocument()
      expect(screen.getByText(/This assignment is locked until/)).toBeInTheDocument()
    })

    it('defaults to "locked until" message when isPastLockDate is not provided', () => {
      const assignment = mockAssignment({
        assignedToDates: [
          {
            dueAt: '2020-10-10T16:00:00Z',
            peerReviewDates: {
              unlockAt: '2020-10-31T06:00:00Z',
              dueAt: null,
              lockAt: null,
            },
          },
        ],
      })
      render(<LockedPeerReview assignment={assignment} />)
      expect(screen.getByTestId('locked-peer-review')).toBeInTheDocument()
      expect(screen.getByText(/This assignment is locked until/)).toBeInTheDocument()
    })
  })
})
