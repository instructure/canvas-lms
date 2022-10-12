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

import CommentsTray from '../CommentsTray/index'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'

async function mockSubmissionCommentQuery(overrides = {}, variableOverrides = {}) {
  const variables = {submissionAttempt: 0, submissionId: '1', ...variableOverrides}
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

describe('CommentsTray', () => {
  let mocks, props

  const renderComponent = () =>
    render(
      <MockedProvider mocks={mocks}>
        <CommentsTray {...props} />
      </MockedProvider>
    )

  beforeEach(async () => {
    const {assignment, submission} = await mockAssignmentAndSubmission()
    props = {closeTray() {}, open: true, assignment, submission, isPeerReviewEnabled: false}
    mocks = await Promise.all([mockSubmissionCommentQuery()])
  })

  it('displays the submission attempt in the tray heading', async () => {
    props.submission.attempt = 4
    const {getByRole} = renderComponent()
    const heading = getByRole('heading', {type: 'h2'})
    expect(heading).toHaveTextContent('Attempt 4 Feedback')
  })

  it('groups submission attempts 0 and 1 into a single attempt (Attempt 1)', async () => {
    props.submission.attempt = 0
    const {rerender, getByRole} = renderComponent()
    expect(getByRole('heading', {type: 'h2'})).toHaveTextContent('Attempt 1 Feedback')

    props.submission.attempt = 1
    rerender(
      <MockedProvider mocks={mocks}>
        <CommentsTray {...props} />
      </MockedProvider>
    )
    expect(getByRole('heading', {type: 'h2'})).toHaveTextContent('Attempt 1 Feedback')
  })

  it('closes the tray when the close button is clicked', async () => {
    props.closeTray = jest.fn()
    const {getByTestId} = renderComponent()
    const closeButton = getByTestId('tray-close-button').getElementsByTagName('button')[0]
    fireEvent.click(closeButton)
    expect(props.closeTray).toHaveBeenCalled()
  })

  it('shows a message in the tray when the student has not submitted and is working off a draft', async () => {
    props.submission.state = 'unsubmitted'
    props.submission.attempt = 2
    const {getByText} = renderComponent()
    const message = getByText('You cannot leave comments until you submit the assignment.')
    expect(message).toBeInTheDocument()
  })

  it('displays "Peer Review Comments" in the tray heading when peer review mode is enabled', async () => {
    const {rerender, getByRole} = renderComponent()
    rerender(
      <MockedProvider mocks={mocks}>
        <CommentsTray {...props} isPeerReviewEnabled={true} />
      </MockedProvider>
    )
    expect(getByRole('heading', {type: 'h2'})).toHaveTextContent('Peer Review Comments')
  })
})
