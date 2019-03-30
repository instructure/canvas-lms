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
import React from 'react'
import Comments from '../Comments'
import CommentsContainer from '../Comments/CommentsContainer'
import {mockAssignment, mockComments, singleComment} from '../../test-utils'
import {MockedProvider} from 'react-apollo/test-utils'
import {SUBMISSION_COMMENT_QUERY} from '../../assignmentData'
import {render, waitForElement} from 'react-testing-library'

const mocks = [
  {
    request: {
      query: SUBMISSION_COMMENT_QUERY,
      variables: {
        submissionId: mockAssignment().submissionsConnection.nodes[0].id.toString()
      }
    },
    result: {
      data: {
        submissionComments: mockComments()
      }
    }
  }
]

describe('Comments', () => {
  it('renders Comments', async () => {
    const {getByTestId} = render(
      <MockedProvider mocks={mocks} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByTestId('comments-container'))).toBeInTheDocument()
  })

  it('renders CommentTextArea', async () => {
    const {getByLabelText} = render(
      <MockedProvider mocks={mocks} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByLabelText('Comment input box'))).toBeInTheDocument()
  })

  it('renders loading indicator when loading query', async () => {
    const {getByTitle} = render(
      <MockedProvider mocks={mocks} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )
    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  it('renders place holder text when no comments', async () => {
    const {getByText} = render(<CommentsContainer comments={[]} />)

    expect(
      await waitForElement(() =>
        getByText('Send a comment to your instructor about this assignment.')
      )
    ).toBeInTheDocument()
  })

  it('renders comment rows when provided', async () => {
    const {container} = render(
      <CommentsContainer comments={[singleComment({_id: '6'}), singleComment()]} />
    )
    expect(container.querySelectorAll('.comment-row-container')).toHaveLength(2)
  })

  it('renders shortname when shortname is provided', async () => {
    const {getAllByText} = render(<CommentsContainer comments={[singleComment()]} />)
    expect(getAllByText('bob builder')).toHaveLength(1)
  })

  it('renders Anonymous when author is not provided', async () => {
    const comment = singleComment()
    comment.author = null
    const {getAllByText, queryAllByText} = render(<CommentsContainer comments={[comment]} />)

    expect(queryAllByText('bob builder')).toHaveLength(0)
    expect(getAllByText('Anonymous')).toHaveLength(1)
  })
})
