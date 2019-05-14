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
import $ from 'jquery'
import CommentContent from '../Comments/CommentContent'
import {
  commentGraphqlMock,
  mockAssignment,
  mockComments,
  singleAttachment,
  singleComment,
  singleMediaObject
} from '../../test-utils'
import {MockedProvider} from 'react-apollo/test-utils'
import {render, waitForElement, fireEvent} from 'react-testing-library'

describe('Comments', () => {
  beforeEach(() => {
    $('body').append('<div role="alert" id=flash_screenreader_holder />')
  })

  it('renders error alert when data returned from mutation fails', async () => {
    const errorMock = commentGraphqlMock(mockComments())
    errorMock[1].result = {errors: [{message: 'Error!'}]}
    const {getByPlaceholderText, getByText} = render(
      <MockedProvider defaultOptions={{mutate: {errorPolicy: 'all'}}} mocks={errorMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))

    expect(
      await waitForElement(() => getByText('Error sending submission comment'))
    ).toBeInTheDocument()
  })

  it('renders Comments', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getByTestId} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByTestId('comments-container'))).toBeInTheDocument()
  })

  it('renders CommentTextArea', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getByLabelText} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByLabelText('Comment input box'))).toBeInTheDocument()
  })

  it('notifies user when comment successfully sent', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getByPlaceholderText, getByText} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))

    expect(await waitForElement(() => getByText('Submission comment sent'))).toBeInTheDocument()
  })

  it('renders the optimistic response with env current user', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getByPlaceholderText, getByText} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))

    expect(await waitForElement(() => getByText('optimistic user'))).toBeInTheDocument()
  })

  it('renders the message when sent', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getAllByTestId, getByPlaceholderText, getByText} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))

    const rows = getAllByTestId('comment-row')
    expect(rows[0]).toHaveTextContent('lion')
    expect(await waitForElement(() => getByText('sent user'))).toBeInTheDocument()
  })

  it('renders loading indicator when loading query', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getByTitle} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )
    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  it('catches error when api returns incorrect data', async () => {
    const noDataMock = commentGraphqlMock(mockComments())
    noDataMock[0].result = {data: null}
    const {getByText} = render(
      <MockedProvider mocks={noDataMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )
    expect(await waitForElement(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  it('renders error when query errors', async () => {
    const errorMock = commentGraphqlMock(mockComments())
    errorMock[0].result = null
    errorMock[0].error = new Error('aw shucks')
    const {getByText} = render(
      <MockedProvider mocks={errorMock} removeTypename addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  // the arc media player has some custom needs for rendering in jsdom that we will need to investigate.  Uncomment when
  // we take this more serious
  // it('renders a media Comment', async () => {
  // const mediaComments = mockComments()
  // mediaComments.commentsConnection.nodes[0].mediaObject = singleMediaObject()
  // const mediaCommentMocks = commentGraphqlMock(mediaComments)

  // const {getByText} = render(
  // <MockedProvider mocks={mediaCommentMocks} addTypename>
  // <Comments assignment={mockAssignment()} />
  // </MockedProvider>
  // )

  // expect(await waitForElement(() => getByText('100x1024'))).toBeInTheDocument()
  // })

  // it('renders an audio only media Comment', async () => {
  // const mediaComment = singleMediaObject({
  // title: 'audio only media comment',
  // mediaType: 'audio/mp4',
  // mediaSources: [
  // {
  // __typename: 'MediaSource',
  // type: 'audio/mp4',
  // src: 'http://some-awesome-url/goes/here',
  // height: '1024',
  // width: '100'
  // }
  // ]
  // })
  // const audioOnlyComments = mockComments()
  // audioOnlyComments.commentsConnection.nodes[0].mediaObject = mediaComment
  // const audioOnlyMocks = commentGraphqlMock(audioOnlyComments)

  // const {container} = render(
  // <MockedProvider mocks={audioOnlyMocks} addTypename>
  // <Comments assignment={mockAssignment()} />
  // </MockedProvider>
  // )

  // const srcElement = await waitForElement(() =>
  // container.querySelector('source[src="http://some-awesome-url/goes/here"]')
  // )
  // expect(srcElement).toBeInTheDocument()
  // })

  it('renders place holder text when no comments', async () => {
    const {getByText} = render(<CommentContent comments={[]} />)

    expect(
      await waitForElement(() =>
        getByText('Send a comment to your instructor about this assignment.')
      )
    ).toBeInTheDocument()
  })

  it('renders comment rows when provided', async () => {
    const comments = [singleComment({_id: '6'}), singleComment()]
    const {getAllByTestId} = render(<CommentContent comments={comments} />)
    const rows = getAllByTestId('comment-row')

    expect(rows).toHaveLength(comments.length)
  })

  it('renders shortname when shortname is provided', async () => {
    const {getAllByText} = render(<CommentContent comments={[singleComment()]} />)
    expect(getAllByText('bob builder')).toHaveLength(1)
  })

  it('renders Anonymous when author is not provided', async () => {
    const comment = singleComment()
    comment.author = null
    const {getAllByText, queryAllByText} = render(<CommentContent comments={[comment]} />)

    expect(queryAllByText('bob builder')).toHaveLength(0)
    expect(getAllByText('Anonymous')).toHaveLength(1)
  })

  it('displays a single attachment', async () => {
    const comment = singleComment()
    const attachment = singleAttachment()
    comment.attachments = [attachment]
    const {getByText} = render(<CommentContent comments={[comment]} />)

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
    const {getByText} = render(<CommentContent comments={[comment]} />)

    expect(
      getByText(attachment1.displayName, {selector: `a[href*='${attachment1.url}']`})
    ).toBeInTheDocument()
    expect(
      getByText(attachment2.displayName, {selector: `a[href*='${attachment2.url}']`})
    ).toBeInTheDocument()
  })

  it('does not display attachments if there are none', async () => {
    const comment = singleComment()
    const {container} = render(<CommentContent comments={[comment]} />)

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
    const {getAllByTestId} = render(<CommentContent comments={comments} />)

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

    const {container, getByText} = render(<CommentContent comments={[comment]} />)

    expect(
      getByText(attachment.displayName, {selector: `a[href*='${attachment.url}']`})
    ).toContainElement(container.querySelector("svg[name='IconPdf']"))
  })
})
