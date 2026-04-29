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
import CommentsTrayBody from '../CommentsTrayBody'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import {render, waitFor} from '@testing-library/react'
import React from 'react'
import StudentViewContext from '@canvas/assignments/react/StudentViewContext'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
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

describe('CommentsTrayBody - group assignments', () => {
  beforeAll(() => {
    fakeENV.setup({current_user: {id: '1'}})
    $('body').append('<div role="alert" id=flash_screenreader_holder />')
  })

  afterAll(() => {
    fakeENV.teardown()
  })

  beforeEach(() => {
    fakeENV.setup({current_user: {id: '1'}, RICH_CONTENT_APP_HOST: '', JWT: '123'})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders warning that comments will be sent to the whole group for group assignments', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission([
      {
        Assignment: {
          gradeGroupStudentsIndividually: false,
          groupCategoryId: '1',
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
      // @ts-expect-error
      <StudentViewContext.Provider
        value={{
          allowChangesToSubmission: true,
          allowPeerReviewComments: true,
          isObserver: false,
        }}
      >
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>,
    )
    await waitFor(() =>
      expect(queryByText('All comments are sent to the whole group.')).toBeInTheDocument(),
    )
  })

  it('does not render warning for grade students individually group assignments', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission([
      {
        Assignment: {
          gradeGroupStudentsIndividually: true,
          groupCategoryId: '1',
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
      // @ts-expect-error
      <StudentViewContext.Provider value={{allowChangesToSubmission: true, isObserver: false}}>
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>,
    )
    await waitFor(() =>
      expect(queryByText('All comments are sent to the whole group.')).not.toBeInTheDocument(),
    )
  })

  it('does not render group comment warning for non-group assignments', async () => {
    const mocks = [await mockSubmissionCommentQuery()]
    const props = await mockAssignmentAndSubmission()
    const {queryByText} = render(
      // @ts-expect-error
      <StudentViewContext.Provider value={{allowChangesToSubmission: true, isObserver: false}}>
        <MockedProvider mocks={mocks}>
          <CommentsTrayBody {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>,
    )
    await waitFor(() =>
      expect(queryByText('All comments are sent to the whole group.')).not.toBeInTheDocument(),
    )
  })
})
