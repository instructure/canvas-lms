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

import {CREATE_SUBMISSION_COMMENT} from '../../graphqlData/Mutations'
import {SUBMISSION_COMMENT_QUERY} from '../../graphqlData/Queries'
import {fireEvent, render, waitForElement} from '@testing-library/react'
import {legacyMockSubmission, mockAssignment, mockComments} from '../../test-utils'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import StudentContent from '../StudentContent'

const mocks = [
  {
    request: {
      query: SUBMISSION_COMMENT_QUERY,
      variables: {
        submissionAttempt: legacyMockSubmission().attempt,
        submissionId: legacyMockSubmission().id
      }
    },
    result: {
      data: {
        submissionComments: mockComments()
      }
    }
  },
  {
    request: {
      query: CREATE_SUBMISSION_COMMENT,
      variables: {
        submissionAttempt: legacyMockSubmission().attempt,
        submissionId: legacyMockSubmission().id
      }
    },
    result: {
      data: null
    }
  }
]

function makeProps(overrides = {}) {
  return {
    assignment: mockAssignment({lockInfo: {isLocked: false}}),
    submission: legacyMockSubmission(),
    ...overrides
  }
}

describe('Assignment Student Content View', () => {
  it('renders the student header if the assignment is unlocked', () => {
    const {getByTestId} = render(
      <MockedProvider>
        <StudentContent {...makeProps()} />
      </MockedProvider>
    )
    expect(getByTestId('assignments-2-student-view')).toBeInTheDocument()
  })

  it('renders the student header if the assignment is locked', () => {
    const props = makeProps({
      assignment: mockAssignment({lockInfo: {isLocked: true}})
    })
    const {getByTestId} = render(<StudentContent {...props} />)
    expect(getByTestId('assignment-student-header-normal')).toBeInTheDocument()
  })

  it('renders the assignment details and student content tab if the assignment is unlocked', () => {
    const {getByRole, getByText, queryByText} = render(
      <MockedProvider>
        <StudentContent {...makeProps()} />
      </MockedProvider>
    )
    expect(getByRole('tablist')).toHaveTextContent('Attempt 1')
    expect(getByText('Details')).toBeInTheDocument()
    expect(queryByText('Availability Dates')).not.toBeInTheDocument()
  })

  it('renders the availability dates if the assignment is locked', () => {
    const props = makeProps({
      assignment: mockAssignment({lockInfo: {isLocked: true}})
    })
    const {queryByRole, getByText} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(queryByRole('tablist')).not.toBeInTheDocument()
    expect(getByText('Availability Dates')).toBeInTheDocument()
  })

  it.skip('renders Comments', async () => {
    // TODO: get this to work in react 16.9
    const {getAllByText, getByText} = render(
      <MockedProvider mocks={mocks} addTypename>
        <StudentContent {...makeProps()} />
      </MockedProvider>
    )
    fireEvent.click(getAllByText('Comments')[0])

    expect(await waitForElement(() => getByText('Send Comment'))).toBeInTheDocument()
  })

  it('renders spinner while lazy loading comments', () => {
    const {getByTitle, getAllByText} = render(
      <MockedProvider mocks={mocks} addTypename>
        <StudentContent {...makeProps()} />
      </MockedProvider>
    )
    fireEvent.click(getAllByText('Comments')[0])
    expect(getByTitle('Loading')).toBeInTheDocument()
  })
})
