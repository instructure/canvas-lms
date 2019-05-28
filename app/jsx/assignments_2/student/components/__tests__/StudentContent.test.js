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

import {CREATE_SUBMISSION_COMMENT, SUBMISSION_COMMENT_QUERY} from '../../assignmentData'
import {fireEvent, render, waitForElement} from 'react-testing-library'
import {legacyMockSubmission, mockAssignment, mockComments, mockSubmission} from '../../test-utils'
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'
import StudentContent from '../StudentContent'

function mockSubmissionHistoryEdges(count, opts = {}) {
  const historyEdges = []
  for (let i = 1; i <= count; i++) {
    const submission = opts.useLegacyMock ? legacyMockSubmission() : mockSubmission()
    submission.attempt = i
    historyEdges.push({
      cursor: btoa(i.toString()),
      node: submission
    })
  }
  return historyEdges
}

function mockPageInfo(options = {}) {
  const optsWithDefaults = {
    hasNextPage: false,
    endCursor: 1,
    ...options
  }

  return {
    hasNextPage: optsWithDefaults.hasNextPage,
    endCursor: btoa(optsWithDefaults.endCursor.toString())
  }
}

const mocks = [
  {
    request: {
      query: SUBMISSION_COMMENT_QUERY,
      variables: {
        submissionId: legacyMockSubmission().rootId
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
        submissionId: legacyMockSubmission().rootId
      }
    },
    result: {
      data: null
    }
  }
]

describe('Assignment Student Content View', () => {
  it('renders the student header if the assignment is unlocked', () => {
    const props = {
      assignment: mockAssignment({lockInfo: {isLocked: false}}),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1, {useLegacyMock: true}),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {getByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(getByTestId('assignments-2-student-view')).toBeInTheDocument()
  })

  it('renders the student header if the assignment is locked', () => {
    const props = {
      assignment: mockAssignment({lockInfo: {isLocked: true}}),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1, {useLegacyMock: true}),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {getByTestId} = render(<StudentContent {...props} />)
    expect(getByTestId('assignment-student-header-normal')).toBeInTheDocument()
  })

  it('renders the assignment details and student content tab if the assignment is unlocked', () => {
    const props = {
      assignment: mockAssignment({lockInfo: {isLocked: false}}),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1, {useLegacyMock: true}),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {getByRole, getByText, queryByText} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(getByRole('tablist')).toHaveTextContent('Upload')
    expect(getByText('Details')).toBeInTheDocument()
    expect(queryByText('Availability Dates')).not.toBeInTheDocument()
  })

  it('renders the availability dates if the assignment is locked', () => {
    const props = {
      assignment: mockAssignment({lockInfo: {isLocked: true}}),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1, {useLegacyMock: true}),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {queryByRole, getByText} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(queryByRole('tablist')).not.toBeInTheDocument()
    expect(getByText('Availability Dates')).toBeInTheDocument()
  })

  it('renders Comments', async () => {
    const props = {
      assignment: mockAssignment({lockInfo: {isLocked: false}}),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1, {useLegacyMock: true}),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {getByText} = render(
      <MockedProvider mocks={mocks} addTypename>
        <StudentContent {...props} />
      </MockedProvider>
    )
    fireEvent.click(getByText('Comments', {selector: '[role=tab]'}))

    expect(await waitForElement(() => getByText('Send Comment'))).toBeInTheDocument()
  })

  it('renders spinner while lazy loading comments', () => {
    const props = {
      assignment: mockAssignment({lockInfo: {isLocked: false}}),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1, {useLegacyMock: true}),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }

    const {getByTitle, getByText} = render(
      <MockedProvider mocks={mocks} addTypename>
        <StudentContent {...props} />
      </MockedProvider>
    )
    fireEvent.click(getByText('Comments', {selector: '[role=tab]'}))
    expect(getByTitle('Loading')).toBeInTheDocument()
  })
})

describe('Next Button', () => {
  it('is disabled if we are at the most current submission', () => {
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {getByText} = render(<StudentContent {...props} />)
    const nextButton = getByText('Load Next')
    expect(nextButton).toHaveAttribute('disabled')
  })

  it('is not disabled if we are not at the most current submission', () => {
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(2),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {getByText} = render(<StudentContent {...props} />)
    const prevButton = getByText('Load Previous')
    const nextButton = getByText('Load Next')
    fireEvent.click(prevButton)
    expect(nextButton).not.toHaveAttribute('disabled')
  })

  it('changes the currently displayed submission to the next one when clicked', () => {
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(3),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {getByText} = render(<StudentContent {...props} />)
    const prevButton = getByText('Load Previous')
    const nextButton = getByText('Load Next')

    // The component will always start with the most current submission, so we
    // need to manually go back a few submissions before clicking the next button
    // in order to test this functionality
    fireEvent.click(prevButton)
    fireEvent.click(prevButton)
    fireEvent.click(nextButton)
    expect(getByText('Attempt 2')).toBeInTheDocument()
  })

  it('does not call onLoadMore() when clicked', () => {
    const mockedOnLoadMore = jest.fn()
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(3),
      pageInfo: mockPageInfo(),
      onLoadMore: mockedOnLoadMore
    }
    const {getByText} = render(<StudentContent {...props} />)
    const nextButton = getByText('Load Next')
    const prevButton = getByText('Load Previous')
    fireEvent.click(prevButton)
    fireEvent.click(nextButton)
    expect(mockedOnLoadMore).not.toHaveBeenCalled()
  })
})

describe('Previous Button', () => {
  it('is disabled if we are at the earliest submission and pagination is exhausted', () => {
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1),
      pageInfo: mockPageInfo({hasNextPage: false}),
      onLoadMore: () => {}
    }
    const {getByText} = render(<StudentContent {...props} />)
    const prevButton = getByText('Load Previous')
    expect(prevButton).toHaveAttribute('disabled')
  })

  it('is not disabled if we are not at the earliest submission', () => {
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(2),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {getByText} = render(<StudentContent {...props} />)
    const prevButton = getByText('Load Previous')
    expect(prevButton).not.toHaveAttribute('disabled')
  })

  it('is not disabled if we are at the earliest submission but have not exhaused pagination', () => {
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1),
      pageInfo: mockPageInfo({hasNextPage: true}),
      onLoadMore: () => {}
    }
    const {getByText} = render(<StudentContent {...props} />)
    const prevButton = getByText('Load Previous')
    expect(prevButton).not.toHaveAttribute('disabled')
  })

  it('changes the currently displayed submission to the previous one when clicked', () => {
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(3),
      pageInfo: mockPageInfo(),
      onLoadMore: () => {}
    }
    const {getByText} = render(<StudentContent {...props} />)
    const prevButton = getByText('Load Previous')
    fireEvent.click(prevButton)
    expect(getByText('Attempt 2')).toBeInTheDocument()
  })

  it('does not call onLoadMore() when the previous item is already fetched', () => {
    const mockedOnLoadMore = jest.fn()
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(2),
      pageInfo: mockPageInfo(),
      onLoadMore: mockedOnLoadMore
    }
    const {getByText} = render(<StudentContent {...props} />)
    const prevButton = getByText('Load Previous')
    fireEvent.click(prevButton)
    expect(mockedOnLoadMore).not.toHaveBeenCalled()
  })

  it('calls onLoadMore() when the previous item has not already been fetched', () => {
    const mockedOnLoadMore = jest.fn()
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1),
      pageInfo: mockPageInfo({hasNextPage: true}),
      onLoadMore: mockedOnLoadMore
    }
    const {getByText} = render(<StudentContent {...props} />)
    const prevButton = getByText('Load Previous')
    fireEvent.click(prevButton)
    expect(mockedOnLoadMore).toHaveBeenCalledTimes(1)
  })

  it('prevents onLoadMore() from being called again until the previous graphql query finishes', () => {
    const mockedOnLoadMore = jest.fn()
    const props = {
      assignment: mockAssignment(),
      submissionHistoryEdges: mockSubmissionHistoryEdges(1),
      pageInfo: mockPageInfo({hasNextPage: true}),
      onLoadMore: mockedOnLoadMore
    }
    const {getByText} = render(<StudentContent {...props} />)
    const prevButton = getByText('Load Previous')
    fireEvent.click(prevButton)
    fireEvent.click(prevButton)
    fireEvent.click(prevButton)
    expect(mockedOnLoadMore).toHaveBeenCalledTimes(1)
  })
})
