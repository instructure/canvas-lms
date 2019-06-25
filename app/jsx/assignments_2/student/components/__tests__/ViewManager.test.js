/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {fireEvent, render, wait} from 'react-testing-library'
import {mockGraphqlQueryResults, mockSubmissionHistory} from '../../test-utils'
import React from 'react'
import ViewManager from '../ViewManager'

function mockSubmissionHistoriesQueryData(opts) {
  const historiesCount = opts.currentAttempt - 1
  const submissionHistories = [...Array(historiesCount)].map((_, i) => {
    const submissionHistory = mockSubmissionHistory()
    submissionHistory.attempt = i + 1
    return submissionHistory
  })

  return {
    node: {
      submissionHistoriesConnection: {
        pageInfo: {
          hasPreviousPage: opts.hasPreviousPage,
          startCursor: btoa('1')
        },
        nodes: submissionHistories
      }
    }
  }
}

function makeProps(opts = {}) {
  const optsWithDefaults = {
    currentAttempt: opts.currentAttempt || 1,
    hasPreviousPage: opts.hasPreviousPage || false,
    loadMoreSubmissionHistories: opts.loadMoreSubmissionHistories || (() => {})
  }
  const {currentAttempt, loadMoreSubmissionHistories} = optsWithDefaults

  const assignment = mockGraphqlQueryResults()
  assignment.submissionsConnection.nodes[0].attempt = currentAttempt

  let submissionHistoriesQueryData = null
  if (currentAttempt > 1) {
    submissionHistoriesQueryData = mockSubmissionHistoriesQueryData(opts)
  }

  return {
    initialQueryData: {assignment},
    loadMoreSubmissionHistories,
    submissionHistoriesQueryData
  }
}

describe('Next Submission Button', () => {
  it('is not displayed if we are at the most current submission', () => {
    const {queryByText} = render(<ViewManager {...makeProps()} />)
    expect(queryByText('View Next Submission')).not.toBeInTheDocument()
  })

  it('is displayed if we are not at the most current submission', async () => {
    const props = makeProps({currentAttempt: 2})
    const {getByText, queryByText} = render(<ViewManager {...props} />)
    const prevButton = getByText('View Previous Submission')
    fireEvent.click(prevButton)
    await wait(() => expect(queryByText('View Next Submission')).toBeInTheDocument())
  })

  it('changes the currently displayed submission to the next one when clicked', () => {
    const props = makeProps({currentAttempt: 3})
    const {getByText} = render(<ViewManager {...props} />)

    // The component will always start with the most current submission, so we
    // need to manually go back a few submissions before clicking the next button
    // in order to test this functionality
    const prevButton = getByText('View Previous Submission')
    fireEvent.click(prevButton)
    fireEvent.click(prevButton)

    const nextButton = getByText('View Next Submission')
    fireEvent.click(nextButton)

    expect(getByText('Attempt 2')).toBeInTheDocument()
  })

  it('does not call loadMoreSubmissionHistories() when clicked', () => {
    const mockedOnLoadMore = jest.fn()
    const props = makeProps({
      currentAttempt: 2,
      loadMoreSubmissionHistories: mockedOnLoadMore
    })
    const {getByText} = render(<ViewManager {...props} />)

    const prevButton = getByText('View Previous Submission')
    fireEvent.click(prevButton)
    const nextButton = getByText('View Next Submission')
    fireEvent.click(nextButton)
    expect(mockedOnLoadMore).not.toHaveBeenCalled()
  })
})

describe('Previous Submission Button', () => {
  it('is not displayed if we are at submission 0', () => {
    const props = makeProps({currentAttempt: 0})
    const {queryByText} = render(<ViewManager {...props} />)
    expect(queryByText('View Previous Submission')).not.toBeInTheDocument()
  })

  it('is not displayed if we are at submission 1', () => {
    const props = makeProps({currentAttempt: 1})
    const {queryByText} = render(<ViewManager {...props} />)
    expect(queryByText('View Previous Submission')).not.toBeInTheDocument()
  })

  it('is displayed if we are not at the earliest submission', () => {
    const props = makeProps({currentAttempt: 2})
    const {getByText} = render(<ViewManager {...props} />)
    expect(getByText('View Previous Submission')).toBeInTheDocument()
  })

  it('is displayed if we are at the earliest submission but have not exhaused pagination', () => {
    const props = makeProps({currentAttempt: 3, hasPreviousPage: true})
    props.submissionHistoriesQueryData.node.submissionHistoriesConnection.nodes.shift()
    const {getByText} = render(<ViewManager {...props} />)
    const prevButton = getByText('View Previous Submission')
    fireEvent.click(prevButton)
    expect(getByText('View Previous Submission')).toBeInTheDocument()
  })

  it('is not displayed if we are at the earliest submission and pagination is exhausted', async () => {
    const props = makeProps({currentAttempt: 3, hasPreviousPage: false})
    props.submissionHistoriesQueryData.node.submissionHistoriesConnection.nodes.shift()
    const {getByText, queryByText} = render(<ViewManager {...props} />)
    const prevButton = getByText('View Previous Submission')
    fireEvent.click(prevButton)
    await wait(() => expect(queryByText('View Previous Submission')).not.toBeInTheDocument())
  })

  it('changes the currently displayed submission to the previous one when clicked', () => {
    const props = makeProps({currentAttempt: 2})
    const {getByText} = render(<ViewManager {...props} />)
    const prevButton = getByText('View Previous Submission')
    fireEvent.click(prevButton)
    expect(getByText('Attempt 1')).toBeInTheDocument()
  })

  it('does not call loadMoreSubmissionHistories() when the previous item is already fetched', () => {
    const mockedOnLoadMore = jest.fn()
    const props = makeProps({currentAttempt: 2, loadMoreSubmissionHistories: mockedOnLoadMore})
    const {getByText} = render(<ViewManager {...props} />)
    const prevButton = getByText('View Previous Submission')
    fireEvent.click(prevButton)
    expect(mockedOnLoadMore).not.toHaveBeenCalled()
  })

  it('calls loadMoreSubmissionHistories() when the previous item has not already been fetched', () => {
    const mockedOnLoadMore = jest.fn()
    const props = makeProps({
      currentAttempt: 2,
      loadMoreSubmissionHistories: mockedOnLoadMore,
      hasPreviousPage: true
    })
    props.submissionHistoriesQueryData.node.submissionHistoriesConnection.nodes.shift()

    const {getByText} = render(<ViewManager {...props} />)
    const prevButton = getByText('View Previous Submission')
    fireEvent.click(prevButton)
    expect(mockedOnLoadMore).toHaveBeenCalledTimes(1)
  })

  it('prevents loadMoreSubmissionHistories() from being called again until graphql query finishes', () => {
    const mockedOnLoadMore = jest.fn()
    const props = makeProps({
      currentAttempt: 2,
      loadMoreSubmissionHistories: mockedOnLoadMore,
      hasPreviousPage: true
    })
    props.submissionHistoriesQueryData.node.submissionHistoriesConnection.nodes.shift()

    const {getByText} = render(<ViewManager {...props} />)
    const prevButton = getByText('View Previous Submission')
    fireEvent.click(prevButton)
    fireEvent.click(prevButton)
    fireEvent.click(prevButton)
    expect(mockedOnLoadMore).toHaveBeenCalledTimes(1)
  })
})
