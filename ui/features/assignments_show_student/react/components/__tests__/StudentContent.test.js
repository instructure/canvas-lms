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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
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
    expect(getByTestId('assignment-student-header-normal')).toBeInTheDocument()
  })

  it('renders the assignment details and student content tab if the assignment is unlocked', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByRole, getByText, queryByText} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(getByRole('tablist')).toHaveTextContent('Attempt 1')
    expect(getByText('Details')).toBeInTheDocument()
    expect(queryByText('Availability Dates')).not.toBeInTheDocument()
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
})
