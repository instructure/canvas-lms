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
import {fireEvent, render} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '../../mocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import StudentContent from '../StudentContent'
import {SUBMISSION_COMMENT_QUERY} from '../../graphqlData/Queries'

jest.mock('../Attempt')

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

  it('renders the availability dates if the assignment is locked', async () => {
    const props = await mockAssignmentAndSubmission({
      LockInfo: {isLocked: true}
    })
    const {queryByRole, getByText} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(queryByRole('tablist')).not.toBeInTheDocument()
    expect(getByText('Availability Dates')).toBeInTheDocument()
  })

  describe('when the comments tab is clicked', () => {
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

    it('renders Comments', async () => {
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {getAllByText, findByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )
      fireEvent.click(getAllByText('Comments')[0])
      expect(await findByText('Send Comment')).toBeInTheDocument()
    })

    it('renders spinner while lazy loading comments', async () => {
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {getByTitle, getAllByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )
      fireEvent.click(getAllByText('Comments')[0])
      expect(getByTitle('Loading')).toBeInTheDocument()
    })
  })
})
