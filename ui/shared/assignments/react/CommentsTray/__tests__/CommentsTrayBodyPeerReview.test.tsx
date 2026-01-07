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
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {COMPLETED_PEER_REVIEW_TEXT} from '@canvas/assignments/helpers/PeerReviewHelpers'
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

describe('CommentsTrayBody - peer review mode enabled', () => {
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

  it('displays an alert when the assignedAssessments for the user is completed for this submission', async () => {
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
          {_id: '3', updatedAt: '2019-03-01T14:32:37-07:00', htmlComment: 'first comment'},
          {_id: '1', updatedAt: '2019-03-03T14:32:37-07:00', htmlComment: 'last comment'},
          {_id: '2', updatedAt: '2019-03-02T14:32:37-07:00', htmlComment: 'middle comment'},
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
      </MockedProvider>,
    )

    await waitFor(() =>
      expect(
        getByText(
          'Add a comment to complete your peer review. You will only see comments written by you.',
        ),
      ).toBeInTheDocument(),
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
      </MockedProvider>,
    )

    await waitFor(() =>
      expect(getByText('You will only see comments written by you.')).toBeInTheDocument(),
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
      mockContext(<CommentsTrayBody {...props} />, mocks),
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
      mockContext(<CommentsTrayBody {...props} />, mocks),
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
      mockContext(<CommentsTrayBody {...props} />, mocks),
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
      mockContext(<CommentsTrayBody {...props} />, mocks),
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
      mockContext(<CommentsTrayBody {...props} />, mocks),
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
    const onSuccessfulPeerReviewMockFunction = vi.fn()
    const props = {
      ...(await getDefaultPropsWithReviewerSubmission('assigned')),
      onSuccessfulPeerReview: onSuccessfulPeerReviewMockFunction,
    }
    props.isPeerReviewEnabled = true
    const {findByPlaceholderText, getByText} = render(
      mockContext(<CommentsTrayBody {...props} />, mocks),
    )
    const textArea = await findByPlaceholderText('Submit a Comment')
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))
    await waitFor(() => expect(onSuccessfulPeerReviewMockFunction).toHaveBeenCalled())
    expect(props.reviewerSubmission.assignedAssessments[0].workflowState).toEqual('completed')
  })
})
