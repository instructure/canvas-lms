// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import $ from 'jquery'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import CommentsTrayBody from '../CommentsTrayBody'
import {MARK_SUBMISSION_COMMENT_READ} from '@canvas/assignments/graphql/student/Mutations'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import {act, render, waitFor} from '@testing-library/react'
import React from 'react'
import StudentViewContext from '@canvas/assignments/react/StudentViewContext'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import fakeENV from '@canvas/test-utils/fakeENV'

async function mockSubmissionCommentQuery(overrides = {}, variableOverrides = {}) {
  const variables = {
    submissionAttempt: 0,
    submissionId: '1',
    peerReview: false,
    ...variableOverrides,
  }
  const allOverrides = [
    {DateTime: '2010-10-16T23:59:59-06:00'},
    {Node: {__typename: 'Submission'}},
    {SubmissionCommentConnection: {nodes: []}},
    overrides,
  ]
  const result = await mockQuery(SUBMISSION_COMMENT_QUERY, allOverrides, variables)
  return {
    request: {
      query: SUBMISSION_COMMENT_QUERY,
      variables,
    },
    result,
  }
}

async function mockMarkSubmissionCommentsRead(overrides) {
  return {
    request: {
      query: MARK_SUBMISSION_COMMENT_READ,
      variables: {commentIds: ['1'], submissionId: '1'},
    },
    ...overrides,
  }
}

let mockedSetOnFailure: (alertMessage: string) => void
let mockedSetOnSuccess: (alertMessage: string) => void

function mockContext(children, mocks = []) {
  return (
    <AlertManagerContext.Provider
      value={{
        setOnFailure: mockedSetOnFailure,
        setOnSuccess: mockedSetOnSuccess,
      }}
    >
      <MockedProvider mocks={mocks}>{children}</MockedProvider>
    </AlertManagerContext.Provider>
  )
}

describe('CommentsTrayBody - read/unread comments', () => {
  beforeAll(() => {
    fakeENV.setup({current_user: {id: '1'}})
    $('body').append('<div role="alert" id=flash_screenreader_holder />')
  })

  afterAll(() => {
    fakeENV.teardown()
  })

  beforeEach(() => {
    fakeENV.setup({current_user: {id: '1'}, RICH_CONTENT_APP_HOST: '', JWT: '123'})
    mockedSetOnFailure = vi.fn().mockResolvedValue({})
    mockedSetOnSuccess = vi.fn().mockResolvedValue({})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('marks submission comments as read after timeout', async () => {
    vi.useFakeTimers()

    const props = await mockAssignmentAndSubmission([
      {
        Submission: {unreadCommentCount: 1},
      },
    ])
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [{read: false}],
      },
    }

    const mockMutation = vi.fn().mockResolvedValue({data: {markSubmissionCommentsRead: {}}})
    const mocks = [
      await mockSubmissionCommentQuery(overrides),
      await mockMarkSubmissionCommentsRead({newData: () => mockMutation()}),
    ]

    render(mockContext(<CommentsTrayBody {...props} />, mocks))

    await act(() => vi.runAllTimers())

    await waitFor(() => expect(mockMutation).toHaveBeenCalledWith(), {timeout: 3000})
  })

  it('does not mark submission comments as read for observers', async () => {
    vi.useFakeTimers()

    const props = await mockAssignmentAndSubmission({
      // @ts-expect-error
      Submission: {unreadCommentCount: 1},
    })
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [{read: false}],
      },
    }

    const mockMutation = vi.fn().mockResolvedValue({data: {markSubmissionCommentsRead: {}}})
    const mocks = [
      await mockSubmissionCommentQuery(overrides),
      await mockMarkSubmissionCommentsRead({newData: () => mockMutation()}),
    ]

    render(
      mockContext(
        // @ts-expect-error
        <StudentViewContext.Provider value={{isObserver: true, allowChangesToSubmission: false}}>
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        </StudentViewContext.Provider>,
      ),
    )

    await act(() => vi.runAllTimers())

    expect(mockMutation).not.toHaveBeenCalled()
  })

  it('renders an error when submission comments fail to be marked as read', async () => {
    vi.useFakeTimers()

    const props = await mockAssignmentAndSubmission([
      {
        Submission: {unreadCommentCount: 1},
      },
    ])
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [{read: false}],
      },
    }
    const mocks = [
      await mockSubmissionCommentQuery(overrides),
      await mockMarkSubmissionCommentsRead({error: new Error('it failed!')}),
    ]

    render(mockContext(<CommentsTrayBody {...props} />, mocks))

    await act(() => vi.advanceTimersByTime(3000))
    await act(() => vi.runAllTimers())

    expect(mockedSetOnFailure).toHaveBeenCalledWith(
      'There was a problem marking submission comments as read',
    )
  })

  it('alerts the screen reader when submission comments are marked as read', async () => {
    vi.useFakeTimers()

    const props = await mockAssignmentAndSubmission([
      {
        Submission: {unreadCommentCount: 1},
      },
    ])
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [{read: false}],
      },
    }

    const result = await mockQuery(MARK_SUBMISSION_COMMENT_READ, [], {
      commentIds: ['1'],
      submissionId: '1',
    })

    const mocks = [
      await mockSubmissionCommentQuery(overrides),
      await mockMarkSubmissionCommentsRead({result}),
    ]

    render(mockContext(<CommentsTrayBody {...props} />, mocks))

    await act(() => vi.advanceTimersByTime(3000))
    await act(() => vi.runAllTimers())

    expect(mockedSetOnSuccess).toHaveBeenCalledWith(
      'All submission comments have been marked as read',
    )
  })
})
