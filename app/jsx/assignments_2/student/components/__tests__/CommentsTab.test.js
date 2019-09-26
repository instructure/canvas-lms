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
import {
  commentGraphqlMock,
  mockAssignment,
  mockComments,
  legacyMockSubmission,
  singleAttachment,
  singleComment
} from '../../test-utils'
import {mockAssignmentAndSubmission} from '../../mocks'
import {MockedProvider} from '@apollo/react-testing'
import {render, waitForElement, fireEvent, wait, act} from '@testing-library/react'
import React from 'react'
import {SUBMISSION_COMMENT_QUERY} from '../../graphqlData/Queries'

function createUnreadCommentMock() {
  const comments = mockComments()
  comments.commentsConnection.nodes[0].read = false

  return [
    {
      request: {
        query: SUBMISSION_COMMENT_QUERY,
        variables: {
          submissionAttempt: 0,
          submissionId: '1'
        }
      },
      result: {
        data: {
          submissionComments: comments
        }
      }
    }
  ]
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

  it('renders error alert when data returned from mutation fails', async () => {
    const errorMock = commentGraphqlMock(mockComments())
    errorMock[1].error = new Error('aw shucks')
    const {getByPlaceholderText, getByText} = render(
      mockContext(
        <MockedProvider
          defaultOptions={{mutate: {errorPolicy: 'all'}}}
          mocks={errorMock}
          addTypename
        >
          <CommentsTab assignment={mockAssignment()} submission={legacyMockSubmission()} />
        </MockedProvider>
      )
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))

    await wait(() =>
      expect(mockedSetOnFailure).toHaveBeenCalledWith('Error sending submission comment')
    )
  })

  it('renders Comments', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getByTestId} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <CommentsTab assignment={mockAssignment()} submission={legacyMockSubmission()} />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByTestId('comments-container'))).toBeInTheDocument()
  })

  it('renders CommentTextArea', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getByLabelText} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <CommentsTab assignment={mockAssignment()} submission={legacyMockSubmission()} />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByLabelText('Comment input box'))).toBeInTheDocument()
  })

  it('notifies user when comment successfully sent', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getByPlaceholderText, getByText} = render(
      mockContext(
        <MockedProvider mocks={basicMock} addTypename>
          <CommentsTab assignment={mockAssignment()} submission={legacyMockSubmission()} />
        </MockedProvider>
      )
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))

    await waitForElement(() => getByText('sent user'))

    expect(mockedSetOnSuccess).toHaveBeenCalledWith('Submission comment sent')
  })

  it('renders the optimistic response with env current user', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {findByPlaceholderText, getByText, findByText} = render(
      mockContext(
        <MockedProvider mocks={basicMock} addTypename>
          <CommentsTab assignment={mockAssignment()} submission={legacyMockSubmission()} />
        </MockedProvider>
      )
    )
    const textArea = await findByPlaceholderText('Submit a Comment')
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))

    expect(await findByText('optimistic user')).toBeTruthy()
  })

  it('renders the message when sent', async () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getAllByTestId, getByPlaceholderText, getByText} = render(
      mockContext(
        <MockedProvider mocks={basicMock} addTypename>
          <CommentsTab assignment={mockAssignment()} submission={legacyMockSubmission()} />
        </MockedProvider>
      )
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))

    const rows = getAllByTestId('comment-row')
    expect(rows[0]).toHaveTextContent('lion')
    expect(await waitForElement(() => getByText('sent user'))).toBeInTheDocument()
  })

  it('renders loading indicator when loading query', () => {
    const basicMock = commentGraphqlMock(mockComments())
    const {getByTitle} = render(
      mockContext(
        <MockedProvider mocks={basicMock} addTypename>
          <CommentsTab assignment={mockAssignment()} submission={legacyMockSubmission()} />
        </MockedProvider>
      )
    )
    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  it('catches error when api returns incorrect data', async () => {
    const noDataMock = commentGraphqlMock(mockComments())
    noDataMock[0].result = {data: null}
    const {getByText} = render(
      mockContext(
        <MockedProvider mocks={noDataMock} addTypename>
          <CommentsTab assignment={mockAssignment()} submission={legacyMockSubmission()} />
        </MockedProvider>
      )
    )
    expect(await waitForElement(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  it('renders error when query errors', async () => {
    const errorMock = commentGraphqlMock(mockComments())
    errorMock[0].result = null
    errorMock[0].error = new Error('aw shucks')
    const {getByText} = render(
      mockContext(
        <MockedProvider mocks={errorMock}>
          <CommentsTab assignment={mockAssignment()} submission={legacyMockSubmission()} />
        </MockedProvider>
      )
    )

    expect(await waitForElement(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })

  it('marks submission comments as read after timeout', async () => {
    jest.useFakeTimers()

    const props = await mockAssignmentAndSubmission({
      Submission: () => ({unreadCommentCount: 1})
    })

    const mockMutation = jest.fn()
    apollo.useMutation = jest.fn(() => [mockMutation, {called: true, error: null}])

    render(
      mockContext(
        <MockedProvider mocks={createUnreadCommentMock()} addTypename>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )

    await wait(() => {
      act(() => jest.runAllTimers())
      expect(mockMutation).toHaveBeenCalledWith({variables: {commentIds: ['1'], submissionId: '1'}})
    })
  })

  it('renders an error when submission comments fail to be marked as read', async () => {
    jest.useFakeTimers()

    const props = await mockAssignmentAndSubmission({
      Submission: () => ({unreadCommentCount: 1})
    })

    apollo.useMutation = jest.fn(() => [jest.fn(), {called: true, error: true}])

    render(
      mockContext(
        <MockedProvider mocks={createUnreadCommentMock()} addTypename>
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
      Submission: () => ({unreadCommentCount: 1})
    })

    apollo.useMutation = jest.fn(() => [jest.fn(), {called: true, error: false}])

    render(
      mockContext(
        <MockedProvider mocks={createUnreadCommentMock()} addTypename>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )

    act(() => jest.advanceTimersByTime(3000))

    expect(mockedSetOnSuccess).toHaveBeenCalledWith(
      'All submission comments have been marked as read'
    )
  })

  // the arc media player has some custom needs for rendering in jsdom that we will need to investigate.  Uncomment when
  // we take this more serious
  // it('renders a media Comment', async () => {
  // const mediaComments = mockComments()
  // mediaComments.commentsConnection.nodes[0].mediaObject = singleMediaObject()
  // const mediaCommentMocks = commentGraphqlMock(mediaComments)

  // const {getByText} = render(
  // <MockedProvider mocks={mediaCommentMocks} addTypename>
  // <CommentsTab assignment={mockAssignment()} />
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
  // <CommentsTab assignment={mockAssignment()} />
  // </MockedProvider>
  // )

  // const srcElement = await waitForElement(() =>
  // container.querySelector('source[src="http://some-awesome-url/goes/here"]')
  // )
  // expect(srcElement).toBeInTheDocument()
  // })

  it('renders place holder text when no comments', async () => {
    const {getByText} = render(
      mockContext(<CommentContent comments={[]} submission={legacyMockSubmission()} />)
    )

    expect(
      await waitForElement(() =>
        getByText('Send a comment to your instructor about this assignment.')
      )
    ).toBeInTheDocument()
  })

  it('renders comment rows when provided', () => {
    const comments = [singleComment({_id: '6'}), singleComment()]
    const {getAllByTestId} = render(
      mockContext(<CommentContent comments={comments} submission={legacyMockSubmission()} />)
    )
    const rows = getAllByTestId('comment-row')

    expect(rows).toHaveLength(comments.length)
  })

  it('renders shortname when shortname is provided', () => {
    const {getAllByText} = render(
      mockContext(
        <CommentContent comments={[singleComment()]} submission={legacyMockSubmission()} />
      )
    )
    expect(getAllByText('bob builder')).toHaveLength(1)
  })

  it('renders Anonymous when author is not provided', () => {
    const comment = singleComment()
    comment.author = null
    const {getAllByText, queryAllByText} = render(
      mockContext(<CommentContent comments={[comment]} submission={legacyMockSubmission()} />)
    )

    expect(queryAllByText('bob builder')).toHaveLength(0)
    expect(getAllByText('Anonymous')).toHaveLength(1)
  })

  it('displays a single attachment', () => {
    const comment = singleComment()
    const attachment = singleAttachment()
    comment.attachments = [attachment]
    const {container, getByText} = render(
      mockContext(<CommentContent comments={[comment]} submission={legacyMockSubmission()} />)
    )

    const renderedAttachment = container.querySelector(`a[href*='${attachment.url}']`)
    expect(renderedAttachment).toBeInTheDocument()
    expect(renderedAttachment).toContainElement(getByText(attachment.displayName))
  })

  it('displays multiple attachments', () => {
    const comment = singleComment()
    const attachment1 = singleAttachment()
    const attachment2 = singleAttachment({
      _id: '30',
      displayName: 'attachment2',
      url: 'https://second-attachment/url.com'
    })
    comment.attachments = [attachment1, attachment2]
    const {container, getByText} = render(
      mockContext(<CommentContent comments={[comment]} submission={legacyMockSubmission()} />)
    )

    const renderedAttachment1 = container.querySelector(`a[href*='${attachment1.url}']`)
    expect(renderedAttachment1).toBeInTheDocument()
    expect(renderedAttachment1).toContainElement(getByText(attachment1.displayName))

    const renderedAttachment2 = container.querySelector(`a[href*='${attachment2.url}']`)
    expect(renderedAttachment2).toBeInTheDocument()
    expect(renderedAttachment2).toContainElement(getByText(attachment2.displayName))
  })

  it('does not display attachments if there are none', () => {
    const comment = singleComment()
    const {container} = render(
      mockContext(<CommentContent comments={[comment]} submission={legacyMockSubmission()} />)
    )

    expect(container.querySelector('a[href]')).toBeNull()
  })

  it('displays the comments in reverse chronological order', () => {
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
    const {getAllByTestId} = render(
      mockContext(<CommentContent comments={comments} submission={legacyMockSubmission()} />)
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

  it('includes an icon on an attachment', () => {
    const comment = singleComment()
    const attachment = singleAttachment()
    comment.attachments = [attachment]

    const {container, getByText} = render(
      mockContext(<CommentContent comments={[comment]} submission={legacyMockSubmission()} />)
    )

    const renderedAttachment = container.querySelector(`a[href*='${attachment.url}']`)
    expect(renderedAttachment).toBeInTheDocument()
    expect(renderedAttachment).toContainElement(getByText(attachment.displayName))
    expect(renderedAttachment).toContainElement(container.querySelector("svg[name='IconPdf']"))
  })
})
