/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import AssignmentDetails from '../AssignmentDetails'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {
  mockAssignment,
  mockAssignmentAndSubmission,
  mockQuery
} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import StudentContent from '../StudentContent'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'

jest.mock('../AttemptSelect')

describe('Assignment Student Content View', () => {
  it('renders the student header if the assignment is unlocked', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(getByTestId('assignments-2-student-view')).toBeInTheDocument()
  })

  it('renders the student header if the assignment is locked', async () => {
    const props = await mockAssignmentAndSubmission({
      LockInfo: {isLocked: true}
    })
    const {getByTestId} = render(<StudentContent {...props} />)
    expect(getByTestId('assignment-student-header')).toBeInTheDocument()
  })

  it('renders the assignment details and student content if the assignment is unlocked', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByText, queryByText} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(getByText('Details')).toBeInTheDocument()
    expect(queryByText('Availability Dates')).not.toBeInTheDocument()
  })

  describe('when the assignment does not expect digital submissions', () => {
    let props
    let oldEnv

    beforeEach(async () => {
      oldEnv = window.ENV
      window.ENV = {...window.ENV}

      props = await mockAssignmentAndSubmission({
        Assignment: {description: 'this is my assignment', nonDigitalSubmission: true},
        Submission: {}
      })
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('renders the assignment details', async () => {
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText(/this is my assignment/)).toBeInTheDocument()
    })

    it('does not render the interface for submitting to the assignment', async () => {
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('assignment-2-student-content-tabs')).not.toBeInTheDocument()
    })

    it('renders a "Mark as Done" button if the assignment is part of a module with a mark-as-done requirement', async () => {
      window.ENV.CONTEXT_MODULE_ITEM = {
        done: false,
        id: '123',
        module_id: '456'
      }

      const {getByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByRole('button', {name: 'Mark as done'})).toBeInTheDocument()
    })

    it('does not render a "Mark as Done" button if the assignment lacks mark-as-done requirements', async () => {
      const {queryByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByRole('button', {name: 'Mark as done'})).not.toBeInTheDocument()
    })
  })

  describe('when the comments tray is opened', () => {
    const makeMocks = async () => {
      const variables = {submissionAttempt: 0, submissionId: '1'}
      const overrides = {
        Node: {__typename: 'Submission'},
        SubmissionCommentConnection: {nodes: []}
      }
      const result = await mockQuery(SUBMISSION_COMMENT_QUERY, overrides, variables)
      const mocks = [
        {
          request: {
            query: SUBMISSION_COMMENT_QUERY,
            variables
          },
          result
        }
      ]
      return mocks
    }

    // https://instructure.atlassian.net/browse/USERS-385
    // eslint-disable-next-line jest/no-disabled-tests
    it.skip('renders Comments', async () => {
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )
      fireEvent.click(getByText('View Feedback'))
      await waitFor(() => expect(getByText('Send Comment')).toBeInTheDocument())
    })

    it('renders spinner while lazy loading comments', async () => {
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {getAllByTitle, getByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )
      fireEvent.click(getByText('View Feedback'))
      expect(getAllByTitle('Loading')[0]).toBeInTheDocument()
    })
  })

  describe('concluded enrollment notice', () => {
    const concludedMatch = /your enrollment in this course has been concluded/

    let oldEnv

    beforeEach(() => {
      oldEnv = window.ENV
      window.ENV = {...window.ENV}
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('renders when the current enrollment is concluded', async () => {
      window.ENV.enrollment_state = 'completed'

      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      expect(getByText(concludedMatch)).toBeInTheDocument()
    })

    it('does not render when the current enrollment is not concluded', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      expect(queryByText(concludedMatch)).not.toBeInTheDocument()
    })
  })

  describe('number of attempts', () => {
    it('renders the number of attempts with one attempt', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1}
      })

      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('1 Attempt')).toBeInTheDocument()
    })

    it('renders the number of attempts with unlimited attempts', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: null}
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('Unlimited Attempts')).toBeInTheDocument()
    })

    it('renders the number of attempts with multiple attempts', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3}
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('3 Attempts')).toBeInTheDocument()
    })

    it('does not render the number of attempts if the assignment does not involve digital submissions', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3, nonDigitalSubmission: true}
      })

      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByText('3 Attempts')).not.toBeInTheDocument()
    })

    it('takes into account extra attempts awarded to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3},
        Submission: {extraAttempts: 2}
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('5 Attempts')).toBeInTheDocument()
    })

    it('treats a null value for extraAttempts as zero', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3},
        Submission: {extraAttempts: null}
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('3 Attempts')).toBeInTheDocument()
    })
  })

  describe('availability dates', () => {
    it('renders AvailabilityDates', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          unlockAt: '2016-07-11T18:00:00-01:00',
          lockAt: '2016-11-11T18:00:00-01:00'
        }
      })
      const {getAllByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      // Reason why this is showing up twice is once for screenreader content and again for regular content
      expect(getAllByText('Available: Jul 11, 2016 7:00pm')).toHaveLength(2)
    })
  })
})
