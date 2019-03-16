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
import {
  commentGraphqlMock,
  mockAssignment,
  mockComments,
  singleAttachment,
  singleComment,
  singleMediaObject
} from '../../test-utils'
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

  it('catches error when api returns incorrect data', async () => {
    const noDataMocks = [
      {
        request: {
          query: SUBMISSION_COMMENT_QUERY,
          variables: {
            submissionId: mockAssignment().submissionsConnection.nodes[0].id.toString()
          }
        },
        result: {
          data: null
        }
      }
    ]
    const {getByText} = render(
      <MockedProvider mocks={noDataMocks} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )
    expect(
      await waitForElement(() => getByText('Something broke unexpectedly.'))
    ).toBeInTheDocument()
  })

  it('renders error when query errors', async () => {
    const errorMock = [
      {
        request: {
          query: SUBMISSION_COMMENT_QUERY,
          variables: {
            submissionId: mockAssignment().submissionsConnection.nodes[0].id.toString()
          }
        },
        error: new Error('aw shucks')
      }
    ]
    const {getByText} = render(
      <MockedProvider mocks={errorMock} removeTypename addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )

    expect(
      await waitForElement(() => getByText('Something broke unexpectedly.'))
    ).toBeInTheDocument()
  })

  it('renders a media Comment', async () => {
    const mediaComments = mockComments()
    mediaComments.commentsConnection.nodes[0].mediaObject = singleMediaObject()
    const mediaCommentMocks = commentGraphqlMock(SUBMISSION_COMMENT_QUERY, mediaComments)

    const {getByTitle} = render(
      <MockedProvider mocks={mediaCommentMocks} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )

    expect(
      await waitForElement(() =>
        getByTitle(mediaComments.commentsConnection.nodes[0].mediaObject.title)
      )
    ).toBeInTheDocument()
  })

  it('renders an audio only media Comment', async () => {
    const mediaComment = singleMediaObject({
      title: 'audio only media comment',
      mediaType: 'audio/mp4',
      mediaSources: {
        __typename: 'MediaSource',
        type: 'audio/mp4',
        src: 'http://some-awesome-url/goes/here'
      }
    })
    const audioOnlyComments = mockComments()
    audioOnlyComments.commentsConnection.nodes[0].mediaObject = mediaComment
    const audioOnlyMocks = commentGraphqlMock(SUBMISSION_COMMENT_QUERY, audioOnlyComments)

    const {getByTitle} = render(
      <MockedProvider mocks={audioOnlyMocks} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByTitle(mediaComment.title))).toBeInTheDocument()
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
    const comments = [singleComment({_id: '6'}), singleComment()]
    const {getAllByTestId} = render(<CommentsContainer comments={comments} />)
    const rows = getAllByTestId('comment-row')

    expect(rows).toHaveLength(comments.length)
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

  it('displays a single attachment', async () => {
    const comment = singleComment()
    const attachment = singleAttachment()
    comment.attachments = [attachment]
    const {getByText} = render(<CommentsContainer comments={[comment]} />)

    expect(
      getByText(attachment.displayName, {selector: `a[href*='${attachment.url}']`})
    ).toBeInTheDocument()
  })

  it('displays multiple attachments', async () => {
    const comment = singleComment()
    const attachment1 = singleAttachment()
    const attachment2 = singleAttachment({
      _id: '30',
      displayName: 'attachment2',
      url: 'https://second-attachment/url.com'
    })
    comment.attachments = [attachment1, attachment2]
    const {getByText} = render(<CommentsContainer comments={[comment]} />)

    expect(
      getByText(attachment1.displayName, {selector: `a[href*='${attachment1.url}']`})
    ).toBeInTheDocument()
    expect(
      getByText(attachment2.displayName, {selector: `a[href*='${attachment2.url}']`})
    ).toBeInTheDocument()
  })

  it('does not display attachments if there are none', async () => {
    const comment = singleComment()
    const {container} = render(<CommentsContainer comments={[comment]} />)

    expect(container.querySelector('a[href]')).toBeNull()
  })

  it('displays the comments in reverse chronological order', async () => {
    const comments = [
      ['2019-03-01T14:32:37-07:00', 'last comment'],
      ['2019-03-03T14:32:37-07:00', 'first comment'],
      ['2019-03-02T14:32:37-07:00', 'middle comment']
    ].map((comment, index) =>
      singleComment({
        _id: index.toString(),
        updatedAt: comment[0],
        comment: comment[1]
      })
    )
    const {getAllByTestId} = render(<CommentsContainer comments={comments} />)

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
    const comment = singleComment()
    const attachment = singleAttachment()
    comment.attachments = [attachment]

    const {container, getByText} = render(<CommentsContainer comments={[comment]} />)

    expect(
      getByText(attachment.displayName, {selector: `a[href*='${attachment.url}']`})
    ).toContainElement(container.querySelector("svg[name='IconPdf']"))
  })
})
