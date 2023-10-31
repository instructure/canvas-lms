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
import * as apollo from 'react-apollo'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import CommentContent from '../CommentsTray/CommentContent'
import CommentsTrayBody from '../CommentsTray/CommentsTrayBody'
import {CREATE_SUBMISSION_COMMENT} from '@canvas/assignments/graphql/student/Mutations'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import {act, fireEvent, render, waitFor} from '@testing-library/react'
import React from 'react'
import StudentViewContext from '../Context'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import {COMPLETED_PEER_REVIEW_TEXT} from '../../helpers/PeerReviewHelpers'

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
    SubmissionComment: {comment: 'test reply comment'},
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
const originalENV = window.ENV

function mockContext(children) {
  return (
    <AlertManagerContext.Provider
      value={{
        setOnFailure: mockedSetOnFailure,
        setOnSuccess: mockedSetOnSuccess,
      }}
    >
      {children}
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
    $('body').append('<div role="alert" id=flash_screenreader_holder />')
  })

  beforeEach(() => {
    // @ts-ignore
    window.ENV = {...originalENV, RICH_CONTENT_APP_HOST: '', JWT: '123'}
    mockedSetOnFailure = jest.fn().mockResolvedValue({})
    mockedSetOnSuccess = jest.fn().mockResolvedValue({})
  })

  afterEach(() => {
    // @ts-ignore
    window.ENV = originalENV
  })

  describe('read/unread comments', () => {
    it('marks submission comments as read after timeout', async () => {
      jest.useFakeTimers()

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
      const mocks = [await mockSubmissionCommentQuery(overrides)]

      const mockMutation = jest.fn()
      // @ts-ignore
      apollo.useMutation = jest.fn(() => [mockMutation, {called: true, error: null}])

      render(
        mockContext(
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        )
      )

      // @ts-ignore
      act(() => jest.runAllTimers())
      await waitFor(() =>
        expect(mockMutation).toHaveBeenCalledWith({
          variables: {commentIds: ['1'], submissionId: '1'},
        })
      )
    })

    it('does not mark submission comments as read for observers', async () => {
      jest.useFakeTimers()

      const props = await mockAssignmentAndSubmission({
        // @ts-ignore
        Submission: {unreadCommentCount: 1},
      })
      const overrides = {
        SubmissionCommentConnection: {
          nodes: [{read: false}],
        },
      }
      const mocks = [await mockSubmissionCommentQuery(overrides)]

      const mockMutation = jest.fn()
      // @ts-ignore
      apollo.useMutation = jest.fn(() => [mockMutation, {called: true, error: null}])

      render(
        mockContext(
          // @ts-ignore
          <StudentViewContext.Provider value={{isObserver: true, allowChangesToSubmission: false}}>
            <MockedProvider mocks={mocks}>
              <CommentsTrayBody {...props} />
            </MockedProvider>
          </StudentViewContext.Provider>
        )
      )

      // @ts-ignore
      act(() => jest.runAllTimers())
      expect(mockMutation).not.toHaveBeenCalled()
    })

    it('renders an error when submission comments fail to be marked as read', async () => {
      jest.useFakeTimers()

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
      const mocks = [await mockSubmissionCommentQuery(overrides)]
      // @ts-ignore
      apollo.useMutation = jest.fn(() => [jest.fn(), {called: true, error: true}])

      render(
        mockContext(
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        )
      )
      // @ts-ignore
      act(() => jest.advanceTimersByTime(3000))

      expect(mockedSetOnFailure).toHaveBeenCalledWith(
        'There was a problem marking submission comments as read'
      )
    })

    it('alerts the screen reader when submission comments are marked as read', async () => {
      jest.useFakeTimers()

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
      const mocks = [await mockSubmissionCommentQuery(overrides)]
      // @ts-ignore
      apollo.useMutation = jest.fn(() => [jest.fn(), {called: true, error: false}])

      render(
        mockContext(
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        )
      )
      // @ts-ignore
      act(() => jest.advanceTimersByTime(3000))

      expect(mockedSetOnSuccess).toHaveBeenCalledWith(
        'All submission comments have been marked as read'
      )
    })
  })

  describe('group assignments', () => {
    // fickle. EVAL-3667
    it.skip('renders warning that comments will be sent to the whole group for group assignments', async () => {
      const mocks = [await mockSubmissionCommentQuery()]
      const props = await mockAssignmentAndSubmission([
        {
          Assignment: {
            gradeGroupStudentsIndividually: false,
            groupSet: {
              _id: '1',
              name: 'sample-group-set',
            },
            submissionTypes: ['online_text_entry', 'online_upload'],
          },
          Submission: {
            ...SubmissionMocks.onlineUploadReadyToSubmit,
          },
        },
      ])
      const {queryByText} = render(
        // @ts-ignore
        <StudentViewContext.Provider value={{allowChangesToSubmission: true, isObserver: false}}>
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        </StudentViewContext.Provider>
      )
      await waitFor(() =>
        expect(queryByText('All comments are sent to the whole group.')).toBeInTheDocument()
      )
    })

    it('does not render warning for grade students individually group assignments', async () => {
      const mocks = [await mockSubmissionCommentQuery()]
      const props = await mockAssignmentAndSubmission([
        {
          Assignment: {
            gradeGroupStudentsIndividually: true,
            groupSet: {
              _id: '1',
              name: 'sample-group-set',
            },
            submissionTypes: ['online_text_entry', 'online_upload'],
          },
          Submission: {
            ...SubmissionMocks.onlineUploadReadyToSubmit,
          },
        },
      ])
      const {queryByText} = render(
        // @ts-ignore
        <StudentViewContext.Provider value={{allowChangesToSubmission: true, isObserver: false}}>
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        </StudentViewContext.Provider>
      )
      await waitFor(() =>
        expect(queryByText('All comments are sent to the whole group.')).not.toBeInTheDocument()
      )
    })

    it('does not render group comment warning for non-group assignments', async () => {
      const mocks = [await mockSubmissionCommentQuery()]
      const props = await mockAssignmentAndSubmission()
      const {queryByText} = render(
        // @ts-ignore
        <StudentViewContext.Provider value={{allowChangesToSubmission: true, isObserver: false}}>
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        </StudentViewContext.Provider>
      )
      await waitFor(() =>
        expect(queryByText('All comments are sent to the whole group.')).not.toBeInTheDocument()
      )
    })
  })

  describe('hidden submissions', () => {
    it('does not render a "Send a comment" message when no comments', async () => {
      const props = await mockAssignmentAndSubmission()
      props.submission.gradeHidden = true
      props.comments = []
      const commentProps = {...props, comments: []}

      const {queryByText} = render(mockContext(<CommentContent {...commentProps} />))

      expect(
        queryByText("This is where you can leave a comment and view your instructor's feedback.")
      ).toBeNull()
    })

    it('renders a message with image if there are no comments', async () => {
      const mocks = [await mockSubmissionCommentQuery()]
      const props = await mockAssignmentAndSubmission()
      props.submission.gradeHidden = true
      const {getByText, getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      )

      await waitFor(() =>
        expect(
          getByText('You may not see all comments for this assignment until grades are posted.')
        ).toBeInTheDocument()
      )
      expect(getByTestId('svg-placeholder-container')).toBeInTheDocument()
    })

    it('renders a message (no image) if there are comments', async () => {
      const overrides = {
        SubmissionCommentConnection: {
          nodes: [{_id: '1'}, {_id: '2'}],
        },
      }
      const mocks = [await mockSubmissionCommentQuery(overrides)]
      const props = await mockAssignmentAndSubmission()
      props.submission.gradeHidden = true
      const {getByText, queryByTestId} = render(
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      )

      await waitFor(() =>
        expect(
          getByText('You may not see all comments for this assignment until grades are posted.')
        ).toBeInTheDocument()
      )
      expect(queryByTestId('svg-placeholder-container')).toBeNull()
    })
  })

  it('renders error alert when data returned from mutation fails', async () => {
    const mocks = await Promise.all([mockSubmissionCommentQuery(), mockCreateSubmissionComment()])
    // @ts-ignore
    mocks[1].error = new Error('aw shucks')
    const props = await mockAssignmentAndSubmission()

    const {getByPlaceholderText, getByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
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
        <CommentsTrayBody {...props} />
      </MockedProvider>
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
      </MockedProvider>
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
      </MockedProvider>
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

    const mocks = [
      await mockSubmissionCommentQuery(overrides),
      await mockSubmissionCommentQuery(overrides, {cursor: 'Hello World'}),
    ]
    const props = await mockAssignmentAndSubmission()

    const querySpy = jest.spyOn(apollo, 'useQuery')

    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTrayBody {...props} />
      </MockedProvider>
    )

    const loadMoreButton = await waitFor(() => getByText('Load Previous Comments'))
    fireEvent.click(loadMoreButton)

    expect(querySpy).toHaveBeenCalledTimes(3)
  })

  it('renders CommentTextArea when the student can make changes to the submission', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {getByLabelText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTrayBody {...props} />
      </MockedProvider>
    )
    expect(await waitFor(() => getByLabelText('Comment input box'))).toBeInTheDocument()
  })

  it('does not render CommentTextArea when the student cannot make changes to the submission', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {queryByLabelText} = render(
      // @ts-ignore
      <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>
    )
    expect(await waitFor(() => queryByLabelText('Comment input box'))).not.toBeInTheDocument()
  })

  it('does not render CommentTextArea when an observer is viewing the submission', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {queryByLabelText} = render(
      // @ts-ignore
      <StudentViewContext.Provider value={{allowChangesToSubmission: false, isObserver: true}}>
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
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
          <CommentsTrayBody {...props} />
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
          <CommentsTrayBody {...props} />
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
          <CommentsTrayBody {...props} />
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
          <CommentsTrayBody {...props} />
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
          <CommentsTrayBody {...props} />
        </MockedProvider>
      )
    )
    expect(await waitFor(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  it('renders error when query errors', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    // @ts-ignore
    mocks[0].error = new Error('aw shucks')
    const props = await mockAssignmentAndSubmission()
    const {getByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      )
    )

    expect(await waitFor(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  it('renders place holder text when no comments', async () => {
    const props = await mockAssignmentAndSubmission()
    const commentProps = {...props, comments: []}

    const {getByText} = render(mockContext(<CommentContent {...commentProps} />))

    expect(
      await waitFor(() =>
        getByText("This is where you can leave a comment and view your instructor's feedback.")
      )
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
          {_id: '3', updatedAt: '2019-03-01T14:32:37-07:00', comment: 'first comment'},
          {_id: '1', updatedAt: '2019-03-03T14:32:37-07:00', comment: 'last comment'},
          {_id: '2', updatedAt: '2019-03-02T14:32:37-07:00', comment: 'middle comment'},
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

  describe('peer review mode enabled', () => {
    it('displays an alert when the assignedAssessments for the user is completed for this submission', async () => {
      const overrides = {
        SubmissionCommentConnection: {
          nodes: [
            {_id: '3', updatedAt: '2019-03-01T14:32:37-07:00', comment: 'first comment'},
            {_id: '1', updatedAt: '2019-03-03T14:32:37-07:00', comment: 'last comment'},
            {_id: '2', updatedAt: '2019-03-02T14:32:37-07:00', comment: 'middle comment'},
          ],
        },
      }
      const comments = await mockComments(overrides)
      const props = await getDefaultPropsWithReviewerSubmission('completed')
      props.submission.gradeHidden = true
      props.isPeerReviewEnabled = true
      const commentProps = {...props, comments}
      const {queryByText} = render(mockContext(<CommentContent {...commentProps} />))

      expect(queryByText('Your peer review is complete!')).toBeInTheDocument()
    })

    it('does not display an alert when peer review mode is disabled', async () => {
      const overrides = {
        SubmissionCommentConnection: {
          nodes: [
            {_id: '3', updatedAt: '2019-03-01T14:32:37-07:00', comment: 'first comment'},
            {_id: '1', updatedAt: '2019-03-03T14:32:37-07:00', comment: 'last comment'},
            {_id: '2', updatedAt: '2019-03-02T14:32:37-07:00', comment: 'middle comment'},
          ],
        },
      }
      const comments = await mockComments(overrides)
      const props = await getDefaultPropsWithReviewerSubmission('completed')
      props.submission.gradeHidden = true
      props.isPeerReviewEnabled = false
      const commentProps = {...props, comments}
      const {queryByText} = render(mockContext(<CommentContent {...commentProps} />))

      expect(queryByText('Your peer review is complete!')).not.toBeInTheDocument()
    })

    it('does not display an alert when the assignedAssessments does not have a completed workflow for this user', async () => {
      const props = await getDefaultPropsWithReviewerSubmission('assigned')
      props.submission.gradeHidden = true
      props.isPeerReviewEnabled = true
      const commentProps = {...props, comments: []}
      const {queryByText} = render(mockContext(<CommentContent {...commentProps} />))

      expect(queryByText('Your peer review is complete!')).not.toBeInTheDocument()
    })

    it('renders a message with image if there are no comments', async () => {
      const mocks = [await mockSubmissionCommentQuery({}, {peerReview: true})]
      const props = await getDefaultPropsWithReviewerSubmission('assigned')
      props.isPeerReviewEnabled = true
      props.assignment.rubric = null
      const {getByText, getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      )

      await waitFor(() =>
        expect(
          getByText(
            'Add a comment to complete your peer review. You will only see comments written by you.'
          )
        ).toBeInTheDocument()
      )
      expect(getByTestId('svg-placeholder-container')).toBeInTheDocument()
    })

    it('renders a message that only comments authored by the viewer are visible if there are no comments and a rubric attached', async () => {
      const mocks = [await mockSubmissionCommentQuery({}, {peerReview: true})]
      const props = await mockAssignmentAndSubmission()
      props.isPeerReviewEnabled = true
      props.assignment.rubric = {id: 123}
      const {getByText, getByTestId} = render(
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      )

      await waitFor(() =>
        expect(getByText('You will only see comments written by you.')).toBeInTheDocument()
      )
      expect(getByTestId('svg-placeholder-container')).toBeInTheDocument()
    })

    it('does not display an alert when the assignment has rubrics', async () => {
      const props = await getDefaultPropsWithReviewerSubmission('completed')
      props.assignment.rubric = {}
      props.submission.gradeHidden = true
      props.isPeerReviewEnabled = true
      const commentProps = {...props, comments: []}

      const {queryByText} = render(mockContext(<CommentContent {...commentProps} />))

      expect(queryByText('Your peer review is complete!')).not.toBeInTheDocument()
    })

    it('shows peer review prompt modal with next peer review if user has other assigned reviews', async () => {
      const mocks = await Promise.all([
        mockSubmissionCommentQuery({}, {peerReview: true}),
        mockCreateSubmissionComment(),
      ])
      const props = await getDefaultPropsWithReviewerSubmission('completed')
      props.isPeerReviewEnabled = true
      const {findByPlaceholderText, getByText, findByText, queryByTestId} = render(
        mockContext(
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        )
      )
      const textArea = await findByPlaceholderText('Submit a Comment')
      fireEvent.change(textArea, {target: {value: 'lion'}})
      fireEvent.click(getByText('Send Comment'))

      expect(await findByText('You have 1 more Peer Review to complete.')).toBeTruthy()
      expect(queryByTestId('peer-review-prompt-modal')).toBeInTheDocument()
    })

    it('shows peer review prompt modal with completed peer review text when no other assigned reviews remaining', async () => {
      const mocks = await Promise.all([
        mockSubmissionCommentQuery({}, {peerReview: true}),
        mockCreateSubmissionComment(),
      ])
      const props = await getDefaultPropsWithReviewerSubmission('assigned')
      props.isPeerReviewEnabled = true
      props.reviewerSubmission.assignedAssessments[1].workflowState = 'completed'
      const {findByPlaceholderText, getByText, findByText, queryByTestId} = render(
        mockContext(
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        )
      )
      const textArea = await findByPlaceholderText('Submit a Comment')
      fireEvent.change(textArea, {target: {value: 'lion'}})
      fireEvent.click(getByText('Send Comment'))

      expect(await findByText(COMPLETED_PEER_REVIEW_TEXT)).toBeTruthy()
      expect(queryByTestId('peer-review-prompt-modal')).toBeInTheDocument()
    })

    it('shows peer review prompt modal with unavailable peer review text when only unavailable reviews remaining', async () => {
      const mocks = await Promise.all([
        mockSubmissionCommentQuery({}, {peerReview: true}),
        mockCreateSubmissionComment(),
      ])
      const props = await getDefaultPropsWithReviewerSubmission('assigned')
      props.isPeerReviewEnabled = true
      props.reviewerSubmission.assignedAssessments[1].assetSubmissionType = null
      const {findByPlaceholderText, getByText, findByText, queryByTestId} = render(
        mockContext(
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        )
      )
      const textArea = await findByPlaceholderText('Submit a Comment')
      fireEvent.change(textArea, {target: {value: 'lion'}})
      fireEvent.click(getByText('Send Comment'))

      expect(await findByText('You have 1 more Peer Review to complete.')).toBeTruthy()
      expect(await findByText('The submission is not available just yet.')).toBeTruthy()
      expect(await findByText('Please check back soon.')).toBeTruthy()
      expect(queryByTestId('peer-review-prompt-modal')).toBeInTheDocument()
    })

    it('does not show peer review modal if user already completed all peer reviews and leaves a comment', async () => {
      const mocks = await Promise.all([
        mockSubmissionCommentQuery({}, {peerReview: true}),
        mockCreateSubmissionComment(),
      ])
      const props = await getDefaultPropsWithReviewerSubmission('completed')
      props.isPeerReviewEnabled = true
      props.reviewerSubmission.assignedAssessments[1].workflowState = 'completed'
      const {findByPlaceholderText, getByText, queryByTestId} = render(
        mockContext(
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        )
      )
      const textArea = await findByPlaceholderText('Submit a Comment')
      fireEvent.change(textArea, {target: {value: 'lion'}})
      fireEvent.click(getByText('Send Comment'))

      expect(queryByTestId('peer-review-prompt-modal')).not.toBeInTheDocument()
    })

    it('does not show peer review modal if assignment has a rubric', async () => {
      const mocks = await Promise.all([
        mockSubmissionCommentQuery({}, {peerReview: true}),
        mockCreateSubmissionComment(),
      ])
      const props = await getDefaultPropsWithReviewerSubmission('completed')
      props.isPeerReviewEnabled = true
      props.assignment.rubric = {}
      const {findByPlaceholderText, getByText, queryByTestId} = render(
        mockContext(
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        )
      )
      const textArea = await findByPlaceholderText('Submit a Comment')
      fireEvent.change(textArea, {target: {value: 'lion'}})
      fireEvent.click(getByText('Send Comment'))

      expect(queryByTestId('peer-review-prompt-modal')).not.toBeInTheDocument()
    })

    it('calls the onSuccessfulPeerReview function to re-render page when a peer review comment is successful', async () => {
      const mocks = await Promise.all([
        mockSubmissionCommentQuery({}, {peerReview: true}),
        mockCreateSubmissionComment(),
      ])
      const onSuccessfulPeerReviewMockFunction = jest.fn()
      const props = {
        ...(await getDefaultPropsWithReviewerSubmission('assigned')),
        onSuccessfulPeerReview: onSuccessfulPeerReviewMockFunction,
      }
      props.isPeerReviewEnabled = true
      const {findByPlaceholderText, getByText} = render(
        mockContext(
          <MockedProvider mocks={mocks}>
            <CommentsTrayBody {...props} />
          </MockedProvider>
        )
      )
      const textArea = await findByPlaceholderText('Submit a Comment')
      fireEvent.change(textArea, {target: {value: 'lion'}})
      fireEvent.click(getByText('Send Comment'))
      await waitFor(() => expect(onSuccessfulPeerReviewMockFunction).toHaveBeenCalled())
      expect(props.reviewerSubmission.assignedAssessments[0].workflowState).toEqual('completed')
    })
  })
})
