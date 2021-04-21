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

import $ from 'jquery'
import * as apollo from 'react-apollo'
import {AlertManagerContext} from '../../../../shared/components/AlertManager'
import CommentContent from '../CommentsTab/CommentContent'
import CommentsTab from '../CommentsTab'
import {CREATE_SUBMISSION_COMMENT} from '../../graphqlData/Mutations'
import {mockAssignmentAndSubmission, mockQuery, mockSubmission} from '../../mocks'
import {MockedProvider} from '@apollo/react-testing'
import {act, fireEvent, render, waitFor} from '@testing-library/react'
import React from 'react'
import StudentViewContext from '../Context'
import {SUBMISSION_COMMENT_QUERY} from '../../graphqlData/Queries'

async function mockSubmissionCommentQuery(overrides = {}, variableOverrides = {}) {
  const variables = {submissionAttempt: 0, submissionId: '1', ...variableOverrides}
  const allOverrides = [
    {DateTime: '2010-10-16T23:59:59-06:00'},
    {Node: {__typename: 'Submission'}},
    {SubmissionCommentConnection: {nodes: []}},
    overrides
  ]
  const result = await mockQuery(SUBMISSION_COMMENT_QUERY, allOverrides, variables)
  return {
    request: {
      query: SUBMISSION_COMMENT_QUERY,
      variables
    },
    result
  }
}

async function mockCreateSubmissionComment() {
  const variables = {
    submissionAttempt: 0,
    id: '1',
    comment: 'lion',
    fileIds: [],
    mediaObjectId: null
  }
  const overrides = {
    DateTime: '2010-11-16T23:59:59-06:00',
    User: {shortName: 'sent user'},
    SubmissionComment: {comment: 'test reply comment'}
  }
  const result = await mockQuery(CREATE_SUBMISSION_COMMENT, overrides, variables)
  return {
    request: {
      query: CREATE_SUBMISSION_COMMENT,
      variables
    },
    result
  }
}

async function mockComments(overrides = {}) {
  const queryResult = await mockSubmissionCommentQuery(overrides)
  return queryResult.result.data.submissionComments.commentsConnection.nodes
}

let mockedSetOnFailure = null
let mockedSetOnSuccess = null

function mockContext(children) {
  return (
    <AlertManagerContext.Provider
      value={{
        setOnFailure: mockedSetOnFailure,
        setOnSuccess: mockedSetOnSuccess
      }}
    >
      {children}
    </AlertManagerContext.Provider>
  )
}

describe('CommentsTab', () => {
  beforeAll(() => {
    $('body').append('<div role="alert" id=flash_screenreader_holder />')
  })

  beforeEach(() => {
    mockedSetOnFailure = jest.fn().mockResolvedValue({})
    mockedSetOnSuccess = jest.fn().mockResolvedValue({})
  })

  // https://instructure.atlassian.net/browse/USERS-379
  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('renders error alert when data returned from mutation fails', async () => {
    const mocks = await Promise.all([mockSubmissionCommentQuery(), mockCreateSubmissionComment()])
    mocks[1].error = new Error('aw shucks')
    const props = await mockAssignmentAndSubmission()

    const {getByPlaceholderText, getByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )
    const textArea = await waitFor(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    await waitFor(() => expect(getByText('lion')).toBeInTheDocument())
    fireEvent.click(getByText('Send Comment'))

    await waitFor(() =>
      expect(mockedSetOnFailure).toHaveBeenCalledWith('Error sending submission comment')
    )
  })

  it('renders Comments', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTab {...props} />
      </MockedProvider>
    )
    await waitFor(() => expect(getByTestId('comments-container')).toBeInTheDocument())
  })

  it('renders Load More Comments button when pages remain', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        pageInfo: {
          hasPreviousPage: true
        }
      }
    }

    const mocks = [await mockSubmissionCommentQuery(overrides)]
    const props = await mockAssignmentAndSubmission()

    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTab {...props} />
      </MockedProvider>
    )

    expect(await waitFor(() => getByText('Load More Comments'))).toBeInTheDocument()
  })

  it('does not render Load More Comments button when no pages remain', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        pageInfo: {
          hasPreviousPage: false
        }
      }
    }

    const mocks = [await mockSubmissionCommentQuery(overrides)]
    const props = await mockAssignmentAndSubmission()

    const {queryByText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTab {...props} />
      </MockedProvider>
    )

    expect(queryByText('Load More Comments')).not.toBeInTheDocument()
  })

  it('loads more comments when button is clicked', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        pageInfo: {
          hasPreviousPage: true
        }
      }
    }

    const mocks = [
      await mockSubmissionCommentQuery(overrides),
      await mockSubmissionCommentQuery(overrides, {cursor: 'Hello World'})
    ]
    const props = await mockAssignmentAndSubmission()

    const querySpy = jest.spyOn(apollo, 'useQuery')

    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTab {...props} />
      </MockedProvider>
    )

    const loadMoreButton = await waitFor(() => getByText('Load More Comments'))
    fireEvent.click(loadMoreButton)

    expect(querySpy).toHaveBeenCalledTimes(3)
  })

  it('renders CommentTextArea when the student can make changes to the submission', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {getByLabelText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTab {...props} />
      </MockedProvider>
    )
    expect(await waitFor(() => getByLabelText('Comment input box'))).toBeInTheDocument()
  })

  it('does not render CommentTextArea when the student cannot make changes to the submission', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {queryByLabelText} = render(
      <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>
    )
    expect(await waitFor(() => queryByLabelText('Comment input box'))).not.toBeInTheDocument()
  })

  it('notifies user when comment successfully sent', async () => {
    const mocks = await Promise.all([mockSubmissionCommentQuery(), mockCreateSubmissionComment()])
    const props = await mockAssignmentAndSubmission()
    const {getByPlaceholderText, getByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )
    const textArea = await waitFor(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))
    await waitFor(() => expect(mockedSetOnSuccess).toHaveBeenCalledWith('Submission comment sent'))
  })

  it('renders the optimistic response with env current user', async () => {
    const mocks = await Promise.all([mockSubmissionCommentQuery(), mockCreateSubmissionComment()])
    const props = await mockAssignmentAndSubmission()
    const {findByPlaceholderText, getByText, findByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )
    const textArea = await findByPlaceholderText('Submit a Comment')
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))

    expect(await findByText('bob')).toBeTruthy()
  })

  it('renders the message when sent', async () => {
    const mocks = await Promise.all([mockSubmissionCommentQuery(), mockCreateSubmissionComment()])
    const props = await mockAssignmentAndSubmission()
    const {getByPlaceholderText, getByText, findByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )
    const textArea = await waitFor(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))
    expect(await findByText('test reply comment')).toBeInTheDocument()
    expect(await findByText(/sent user/i)).toBeInTheDocument()
  })

  it('renders loading indicator when loading query', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {getByTitle} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )
    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  it('catches error when api returns incorrect data', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    mocks[0].result = {data: null}
    const props = await mockAssignmentAndSubmission()
    const {getByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )
    expect(await waitFor(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  it('renders error when query errors', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    mocks[0].error = new Error('aw shucks')
    const props = await mockAssignmentAndSubmission()
    const {getByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )

    expect(await waitFor(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  it('marks submission comments as read after timeout', async () => {
    jest.useFakeTimers()

    const props = await mockAssignmentAndSubmission({
      Submission: {unreadCommentCount: 1}
    })
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [{read: false}]
      }
    }
    const mocks = [await mockSubmissionCommentQuery(overrides)]

    const mockMutation = jest.fn()
    apollo.useMutation = jest.fn(() => [mockMutation, {called: true, error: null}])

    render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )

    jest.runAllTimers()
    await waitFor(() =>
      expect(mockMutation).toHaveBeenCalledWith({variables: {commentIds: ['1'], submissionId: '1'}})
    )
  })

  it('renders an error when submission comments fail to be marked as read', async () => {
    jest.useFakeTimers()

    const props = await mockAssignmentAndSubmission({
      Submission: {unreadCommentCount: 1}
    })
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [{read: false}]
      }
    }
    const mocks = [await mockSubmissionCommentQuery(overrides)]

    apollo.useMutation = jest.fn(() => [jest.fn(), {called: true, error: true}])

    render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )

    act(() => jest.advanceTimersByTime(3000))

    expect(mockedSetOnFailure).toHaveBeenCalledWith(
      'There was a problem marking submission comments as read'
    )
  })

  it('alerts the screen reader when submission comments are marked as read', async () => {
    jest.useFakeTimers()

    const props = await mockAssignmentAndSubmission({
      Submission: {unreadCommentCount: 1}
    })
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [{read: false}]
      }
    }
    const mocks = [await mockSubmissionCommentQuery(overrides)]

    apollo.useMutation = jest.fn(() => [jest.fn(), {called: true, error: false}])

    render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )

    act(() => jest.advanceTimersByTime(3000))

    expect(mockedSetOnSuccess).toHaveBeenCalledWith(
      'All submission comments have been marked as read'
    )
  })

  it('renders place holder text when no comments', async () => {
    const submission = await mockSubmission()
    const {getByText} = render(
      mockContext(<CommentContent comments={[]} submission={submission} />)
    )

    expect(
      await waitFor(() => getByText('Send a comment to your instructor about this assignment.'))
    ).toBeInTheDocument()
  })

  it('renders comment rows when provided', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [{_id: '1'}, {_id: '2'}]
      }
    }
    const comments = await mockComments(overrides)
    const submission = await mockSubmission()
    const {getAllByTestId} = render(
      mockContext(<CommentContent comments={comments} submission={submission} />)
    )
    const rows = getAllByTestId('comment-row')

    expect(rows).toHaveLength(comments.length)
  })

  it('renders shortname when shortname is provided', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{}]},
      User: {shortName: 'bob builder'}
    }
    const comments = await mockComments(overrides)
    const submission = await mockSubmission()
    const {getAllByText} = render(
      mockContext(<CommentContent comments={comments} submission={submission} />)
    )
    expect(getAllByText('bob builder')).toHaveLength(1)
  })

  it('renders Anonymous when author is not provided', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{author: null}]}
    }
    const comments = await mockComments(overrides)
    const submission = await mockSubmission()
    const {getAllByText, queryAllByText} = render(
      mockContext(<CommentContent comments={comments} submission={submission} />)
    )

    expect(queryAllByText('bob builder')).toHaveLength(0)
    expect(getAllByText('Anonymous')).toHaveLength(1)
  })

  it('displays a single attachment', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{}]},
      File: {url: 'test-url.com', displayName: 'Test Display Name'}
    }
    const comments = await mockComments(overrides)
    const submission = await mockSubmission()
    const {container, getByText} = render(
      mockContext(<CommentContent comments={comments} submission={submission} />)
    )

    const renderedAttachment = container.querySelector("a[href*='test-url.com']")
    expect(renderedAttachment).toBeInTheDocument()
    expect(renderedAttachment).toContainElement(getByText('Test Display Name'))
  })

  it('displays multiple attachments', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [
          {
            attachments: [
              {url: 'attachment1.com', displayName: 'attachment1'},
              {url: 'attachment2.com', displayName: 'attachment2'}
            ]
          }
        ]
      }
    }
    const comments = await mockComments(overrides)
    const submission = await mockSubmission()
    const {container, getByText} = render(
      mockContext(<CommentContent comments={comments} submission={submission} />)
    )

    const renderedAttachment1 = container.querySelector("a[href*='attachment1.com']")
    expect(renderedAttachment1).toBeInTheDocument()
    expect(renderedAttachment1).toContainElement(getByText('attachment1'))

    const renderedAttachment2 = container.querySelector("a[href*='attachment2.com']")
    expect(renderedAttachment2).toBeInTheDocument()
    expect(renderedAttachment2).toContainElement(getByText('attachment2'))
  })

  it('does not display attachments if there are none', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{attachments: []}]}
    }
    const comments = await mockComments(overrides)
    const submission = await mockSubmission()

    const {container} = render(
      mockContext(<CommentContent comments={comments} submission={submission} />)
    )

    expect(container.querySelector('a[href]')).toBeNull()
  })

  it('displays the comments in reverse chronological order', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [
          {_id: '3', updatedAt: '2019-03-01T14:32:37-07:00', comment: 'last comment'},
          {_id: '1', updatedAt: '2019-03-03T14:32:37-07:00', comment: 'first comment'},
          {_id: '2', updatedAt: '2019-03-02T14:32:37-07:00', comment: 'middle comment'}
        ]
      }
    }
    const comments = await mockComments(overrides)
    const submission = await mockSubmission()

    const {getAllByTestId} = render(
      mockContext(<CommentContent comments={comments} submission={submission} />)
    )

    const rows = getAllByTestId('comment-row')

    expect(rows).toHaveLength(comments.length)
    expect(rows[0]).toHaveTextContent('first comment')
    expect(rows[0]).toHaveTextContent('Sun Mar 3, 2019 9:32pm')
    expect(rows[1]).toHaveTextContent('middle comment')
    expect(rows[1]).toHaveTextContent('Sat Mar 2, 2019 9:32pm')
    expect(rows[2]).toHaveTextContent('last comment')
    expect(rows[2]).toHaveTextContent('Fri Mar 1, 2019 9:32pm')
  })

  it('includes an icon on an attachment', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{}]},
      File: {url: 'test-url.com', displayName: 'Test Display Name', mimeClass: 'pdf'}
    }
    const comments = await mockComments(overrides)
    const submission = await mockSubmission()

    const {container, getByText} = render(
      mockContext(<CommentContent comments={comments} submission={submission} />)
    )

    const renderedAttachment = container.querySelector("a[href*='test-url.com']")
    expect(renderedAttachment).toBeInTheDocument()
    expect(renderedAttachment).toContainElement(getByText('Test Display Name'))
    expect(renderedAttachment).toContainElement(container.querySelector("svg[name='IconPdf']"))
  })
})
