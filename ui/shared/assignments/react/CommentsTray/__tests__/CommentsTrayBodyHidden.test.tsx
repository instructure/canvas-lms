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
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import {render, waitFor} from '@testing-library/react'
import React from 'react'
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

describe('CommentsTrayBody - hidden submissions', () => {
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

  it('does not render a "Send a comment" message when no comments', async () => {
    const props = await mockAssignmentAndSubmission()
    props.submission.gradeHidden = true
    props.comments = []
    const commentProps = {...props, comments: []}

    const {queryByText} = render(mockContext(<CommentContent {...commentProps} />))

    expect(
      queryByText("This is where you can leave a comment and view your instructor's feedback."),
    ).toBeNull()
  })

  it('renders a message with image if there are no comments', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    props.submission.gradeHidden = true
    const {getByText, getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTrayBody {...props} />
      </MockedProvider>,
    )

    await waitFor(() =>
      expect(
        getByText('You may not see all comments for this assignment until grades are posted.'),
      ).toBeInTheDocument(),
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
      </MockedProvider>,
    )

    await waitFor(() =>
      expect(
        getByText('You may not see all comments for this assignment until grades are posted.'),
      ).toBeInTheDocument(),
    )
    expect(queryByTestId('svg-placeholder-container')).toBeNull()
  })
})
