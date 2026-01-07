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
import CommentContent from '../CommentContent'
import CommentsTrayBody from '../CommentsTrayBody'
import {CREATE_SUBMISSION_COMMENT} from '@canvas/assignments/graphql/student/Mutations'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import {fireEvent, render, waitFor} from '@testing-library/react'
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

async function mockCreateSubmissionComment() {
  const variables = {
    submissionAttempt: 0,
    id: '1',
    comment: 'lion',
    fileIds: [],
    mediaObjectId: null,
    mediaObjectType: null,
  }
  const overrides = {
    DateTime: '2010-11-16T23:59:59-06:00',
    User: {shortName: 'sent user'},
    SubmissionComment: {htmlComment: 'test reply comment'},
  }

  const result = await mockQuery(CREATE_SUBMISSION_COMMENT, [overrides], variables)
  return {
    request: {
      query: CREATE_SUBMISSION_COMMENT,
      variables,
    },
    result,
  }
}

async function mockComments(overrides = {}) {
  const queryResult = await mockSubmissionCommentQuery(overrides)

  return queryResult.result.data?.submissionComments.commentsConnection.nodes
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

const getDefaultPropsWithReviewerSubmission = async (workflowState: string) => {
  const props = await mockAssignmentAndSubmission()
  const assetId = props.submission._id as string
  const reviewerSubmission: {
    id: string
    _id: string
    assignedAssessments: {
      assetId: string
      workflowState: string
      assetSubmissionType: string | null
    }[]
  } = {
    id: 'test-id',
    _id: 'test-id',
    assignedAssessments: [
      {
        assetId,
        workflowState,
        assetSubmissionType: 'online-text',
      },
      {
        assetId: 'some other user id',
        workflowState: 'assigned',
        assetSubmissionType: 'online-text',
      },
    ],
  }

  return {...props, reviewerSubmission, isPeerReviewEnabled: false}
}

describe('CommentsTrayBody', () => {
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

  it('renders error alert when data returned from mutation fails', async () => {
    const mocks = await Promise.all([mockSubmissionCommentQuery(), mockCreateSubmissionComment()])
    // @ts-expect-error
    mocks[1].error = new Error('aw shucks')
    const props = await mockAssignmentAndSubmission()

    const {getByPlaceholderText, getByText} = render(
      mockContext(<CommentsTrayBody {...props} />, mocks),
    )
    const textArea = await waitFor(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    await waitFor(() => expect(getByText('lion')).toBeInTheDocument())
    fireEvent.click(getByText('Send Comment'))

    await waitFor(() =>
      expect(mockedSetOnFailure).toHaveBeenCalledWith('Error sending submission comment'),
    )
  })

  it('renders Comments', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTrayBody {...props} />
      </MockedProvider>,
    )
    await waitFor(() => expect(getByTestId('comments-container')).toBeInTheDocument())
  })

  it('renders Load Previous Comments button when pages remain', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        pageInfo: {
          hasPreviousPage: true,
        },
      },
    }

    const mocks = [await mockSubmissionCommentQuery(overrides)]
    const props = await mockAssignmentAndSubmission()

    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTrayBody {...props} />
      </MockedProvider>,
    )

    expect(await waitFor(() => getByText('Load Previous Comments'))).toBeInTheDocument()
  })

  it('does not render Load Previous Comments button when no pages remain', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        pageInfo: {
          hasPreviousPage: false,
        },
      },
    }

    const mocks = [await mockSubmissionCommentQuery(overrides)]
    const props = await mockAssignmentAndSubmission()

    const {queryByText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTrayBody {...props} />
      </MockedProvider>,
    )

    expect(queryByText('Load Previous Comments')).not.toBeInTheDocument()
  })

  it('loads previous comments when button is clicked', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        pageInfo: {
          hasPreviousPage: true,
        },
      },
    }

    const cursorMock = await mockSubmissionCommentQuery(overrides, {cursor: 'Hello World'})
    const cursorMockWrapper = vi.fn().mockReturnValue(cursorMock.result)

    const mocks = [
      await mockSubmissionCommentQuery(overrides),
      {...cursorMock, result: cursorMockWrapper},
    ]
    const props = await mockAssignmentAndSubmission()

    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTrayBody {...props} />
      </MockedProvider>,
    )

    const loadMoreButton = await waitFor(() => getByText('Load Previous Comments'))
    fireEvent.click(loadMoreButton)
    await waitFor(() => expect(cursorMockWrapper).toHaveBeenCalled())
  })

  it('renders CommentTextArea when the student can make changes to the submission', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {getByLabelText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTrayBody {...props} />
      </MockedProvider>,
    )
    expect(await waitFor(() => getByLabelText('Comment input box'))).toBeInTheDocument()
  })

  it('does not render CommentTextArea when the student cannot make changes to the submission', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {queryByLabelText} = render(
      // @ts-expect-error
      <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>,
    )
    expect(await waitFor(() => queryByLabelText('Comment input box'))).not.toBeInTheDocument()
  })

  it('does not render CommentTextArea when an observer is viewing the submission', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {queryByLabelText} = render(
      // @ts-expect-error
      <StudentViewContext.Provider value={{allowChangesToSubmission: false, isObserver: true}}>
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>,
    )
    expect(await waitFor(() => queryByLabelText('Comment input box'))).not.toBeInTheDocument()
  })

  it('notifies user when comment successfully sent', async () => {
    const mocks = await Promise.all([mockSubmissionCommentQuery(), mockCreateSubmissionComment()])
    const props = await mockAssignmentAndSubmission()
    const {getByPlaceholderText, getByText} = render(
      mockContext(<CommentsTrayBody {...props} />, mocks),
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
      mockContext(<CommentsTrayBody {...props} />, mocks),
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
      mockContext(<CommentsTrayBody {...props} />, mocks),
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
    const {getByTitle} = render(mockContext(<CommentsTrayBody {...props} />, mocks))
    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  it('catches error when api returns incorrect data', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    mocks[0].result = {data: null}
    const props = await mockAssignmentAndSubmission()
    const {getByText} = render(mockContext(<CommentsTrayBody {...props} />, mocks))
    expect(await waitFor(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  it('renders error when query errors', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    // @ts-expect-error
    mocks[0].result = {errors: new Error('aw shucks')}
    const props = await mockAssignmentAndSubmission()
    const {getByText} = render(mockContext(<CommentsTrayBody {...props} />, mocks))

    expect(await waitFor(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  it('renders place holder text when no comments', async () => {
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments: []}

    const {getByText} = render(mockContext(<CommentContent {...commentProps} />))

    expect(
      await waitFor(() =>
        getByText("This is where you can leave a comment and view your instructor's feedback."),
      ),
    ).toBeInTheDocument()
  })

  it('renders comment rows when provided', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [{_id: '1'}, {_id: '2'}],
      },
    }
    const comments = await mockComments(overrides)
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments}
    const {getAllByTestId} = render(mockContext(<CommentContent {...commentProps} />))
    const rows = getAllByTestId('comment-row')

    expect(rows).toHaveLength(comments.length)
  })

  it('renders comments without html tags', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [
          {_id: '3', updatedAt: '2019-03-01T14:32:37-07:00', htmlComment: '<p>html comment</p>'},
        ],
      },
    }
    const comments = await mockComments(overrides)
    const props = await getDefaultPropsWithReviewerSubmission('completed')
    props.submission.gradeHidden = true
    props.isPeerReviewEnabled = false
    const commentProps = {...props, comments}
    const {getByTestId} = render(mockContext(<CommentContent {...commentProps} />))

    expect(getByTestId('commentContent').textContent).toBe('html comment')
  })

  it('preserves \n formatting in comments', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [
          {_id: '3', updatedAt: '2019-03-01T14:32:37-07:00', htmlComment: 'formatted\ncomment'},
        ],
      },
    }
    const comments = await mockComments(overrides)
    const props = await getDefaultPropsWithReviewerSubmission('completed')
    props.submission.gradeHidden = true
    props.isPeerReviewEnabled = false
    const commentProps = {...props, comments}
    const {getByTestId} = render(mockContext(<CommentContent {...commentProps} />))

    expect(getByTestId('commentContent').innerHTML).toBe('formatted<br>\ncomment')
  })

  it('renders shortname when shortname is provided', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{}]},
      User: {shortName: 'bob builder'},
    }
    const comments = await mockComments(overrides)
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments}
    const {getAllByText} = render(mockContext(<CommentContent {...commentProps} />))
    expect(getAllByText('bob builder')).toHaveLength(1)
  })

  it('renders Anonymous when author is not provided', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{author: null}]},
    }
    const comments = await mockComments(overrides)
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments}
    const {getAllByText, queryAllByText} = render(mockContext(<CommentContent {...commentProps} />))

    expect(queryAllByText('bob builder')).toHaveLength(0)
    expect(getAllByText('Anonymous')).toHaveLength(1)
  })

  it('displays a single attachment', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{}]},
      File: {url: 'test-url.com', displayName: 'Test Display Name'},
    }
    const comments = await mockComments(overrides)
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments}
    const {container, getByText} = render(mockContext(<CommentContent {...commentProps} />))

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
              {url: 'attachment2.com', displayName: 'attachment2'},
            ],
          },
        ],
      },
    }
    const comments = await mockComments(overrides)
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments}
    const {container, getByText} = render(mockContext(<CommentContent {...commentProps} />))

    const renderedAttachment1 = container.querySelector("a[href*='attachment1.com']")
    expect(renderedAttachment1).toBeInTheDocument()
    expect(renderedAttachment1).toContainElement(getByText('attachment1'))

    const renderedAttachment2 = container.querySelector("a[href*='attachment2.com']")
    expect(renderedAttachment2).toBeInTheDocument()
    expect(renderedAttachment2).toContainElement(getByText('attachment2'))
  })

  it('does not display attachments if there are none', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{attachments: []}]},
    }
    const comments = await mockComments(overrides)
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments}

    const {container} = render(mockContext(<CommentContent {...commentProps} />))

    expect(container.querySelector('a[href]')).toBeNull()
  })

  it('displays the comments in chronological order', async () => {
    const overrides = {
      SubmissionCommentConnection: {
        nodes: [
          {_id: '3', updatedAt: '2019-03-01T14:32:37-07:00', htmlComment: 'first comment'},
          {_id: '1', updatedAt: '2019-03-03T14:32:37-07:00', htmlComment: 'last comment'},
          {_id: '2', updatedAt: '2019-03-02T14:32:37-07:00', htmlComment: 'middle comment'},
        ],
      },
    }
    const comments = await mockComments(overrides)
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments}

    const {getAllByTestId} = render(mockContext(<CommentContent {...commentProps} />))

    const rows = getAllByTestId('comment-row')

    expect(rows).toHaveLength(comments.length)
    expect(rows[0]).toHaveTextContent('first comment')
    expect(rows[0]).toHaveTextContent('Fri Mar 1, 2019 9:32pm')
    expect(rows[1]).toHaveTextContent('middle comment')
    expect(rows[1]).toHaveTextContent('Sat Mar 2, 2019 9:32pm')
    expect(rows[2]).toHaveTextContent('last comment')
    expect(rows[2]).toHaveTextContent('Sun Mar 3, 2019 9:32pm')
  })

  it('includes an icon on an attachment', async () => {
    const overrides = {
      SubmissionCommentConnection: {nodes: [{}]},
      File: {url: 'test-url.com', displayName: 'Test Display Name', mimeClass: 'pdf'},
    }
    const comments = await mockComments(overrides)
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments}

    const {container, getByText} = render(mockContext(<CommentContent {...commentProps} />))

    const renderedAttachment = container.querySelector("a[href*='test-url.com']")
    expect(renderedAttachment).toBeInTheDocument()
    expect(renderedAttachment).toContainElement(getByText('Test Display Name'))
    expect(renderedAttachment).toContainElement(container.querySelector("svg[name='IconPdf']"))
  })
})
