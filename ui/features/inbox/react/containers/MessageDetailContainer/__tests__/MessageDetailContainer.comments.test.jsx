/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from '@apollo/client'
import {handlers} from '../../../../graphql/mswHandlers'
import {MessageDetailContainer} from '../MessageDetailContainer'
import {Conversation} from '../../../../graphql/Conversation'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import React from 'react'
import waitForApolloLoading from '../../../../util/waitForApolloLoading'
import {responsiveQuerySizes} from '../../../../util/utils'
import {render, waitFor} from '@testing-library/react'
import {ConversationContext} from '../../../../util/constants'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn(),
}))
describe('MessageDetailContainer', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    server.listen()

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })

    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'},
    }))
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  const setup = ({
    conversation = Conversation.mock(),
    isSubmissionCommentsType = false,
    onReply = jest.fn(),
    onReplyAll = jest.fn(),
    onDelete = jest.fn(),
    onForward = jest.fn(),
    onReadStateChange = jest.fn(),
    setOnSuccess = jest.fn(),
    setCanReply = jest.fn(),
    overrideProps = {},
  } = {}) =>
    render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess}}>
          <ConversationContext.Provider value={{isSubmissionCommentsType}}>
            <MessageDetailContainer
              conversation={conversation}
              onReply={onReply}
              onReplyAll={onReplyAll}
              onDelete={onDelete}
              onForward={onForward}
              onReadStateChange={onReadStateChange}
              setCanReply={setCanReply}
              {...overrideProps}
            />
          </ConversationContext.Provider>
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )

  describe('submission comments', () => {
    const mockSubmissionComment = {
      _id: '1',
      id: 'Submission-1',
      subject: 'Assignment: Test Assignment',
      workflowState: 'unread',
      canReply: false,
      commentsConnection: {
        nodes: [
          {
            _id: '1',
            id: 'SubmissionComment-1',
            submissionId: '1',
            createdAt: '2024-01-24T11:35:35-07:00',
            attempt: 1,
            canReply: false,
            author: {
              _id: '1',
              id: 'VXNlci0x',
              name: 'Student Name',
              shortName: 'Student',
              pronouns: null,
              avatarUrl: null,
              __typename: 'User',
            },
            assignment: {
              _id: '1',
              id: 'QXNzaWdubWVudC0x',
              name: 'Test Assignment',
              htmlUrl: '/courses/1/assignments/1',
              __typename: 'Assignment',
            },
            comment: 'my student comment',
            htmlComment: '<p>my student comment</p>',
            course: {
              _id: '1',
              id: 'Q291cnNlLTE=',
              name: 'Test Course',
              courseNickname: null,
              contextName: 'Test Course',
              assetString: 'course_1',
              __typename: 'Course',
            },
            read: false,
            __typename: 'SubmissionComment',
          },
        ],
        pageInfo: {
          hasNextPage: false,
          endCursor: null,
          __typename: 'PageInfo',
        },
        __typename: 'SubmissionCommentConnection',
      },
    }

    describe('rendering', () => {
      it('should render conversation information correctly', async () => {
        const {findByTestId, findByText} = setup({
          isSubmissionCommentsType: true,
          conversation: mockSubmissionComment,
        })

        await waitFor(
          async () => {
            const header = await findByTestId('message-detail-header-desktop')
            expect(header).toBeInTheDocument()
            const commentText = await findByText('my student comment')
            expect(commentText).toBeInTheDocument()
          },
          {
            timeout: 1000,
          },
        )
      })

      it('should not render the reply or reply_all option in header if student lacks permission', async () => {
        const noReplyMock = {
          ...mockSubmissionComment,
          commentsConnection: {
            ...mockSubmissionComment.commentsConnection,
            nodes: [
              {
                ...mockSubmissionComment.commentsConnection.nodes[0],
                canReply: false,
              },
            ],
          },
        }
        const {queryByTestId} = setup({
          isSubmissionCommentsType: true,
          conversation: noReplyMock,
        })
        expect(queryByTestId('message-detail-header-reply-btn')).not.toBeInTheDocument()
      })

      it('should render with link in title', async () => {
        const container = setup({
          isSubmissionCommentsType: true,
          conversation: mockSubmissionComment,
        })
        expect(container).toBeTruthy()
        await waitFor(() =>
          expect(container.getByTestId('submission-comment-header-line')).toBeTruthy(),
        )
      })

      it('should not render reply option', async () => {
        const container = setup({
          isSubmissionCommentsType: true,
          conversation: mockSubmissionComment,
        })
        await waitForApolloLoading()
        expect(container.queryByTestId('message-reply')).not.toBeInTheDocument()
      })

      it('should not render more options', async () => {
        const container = setup({
          isSubmissionCommentsType: true,
          conversation: mockSubmissionComment,
        })
        await waitForApolloLoading()
        expect(container.queryByTestId('message-more-options')).not.toBeInTheDocument()
      })

      it('should mark loaded submission comments as read', async () => {
        const mockReadStateChange = jest.fn()
        const container = setup({
          conversation: mockSubmissionComment,
          onReadStateChange: mockReadStateChange,
        })
        await container.findAllByTestId('message-more-options')

        await waitForApolloLoading()
        expect(mockReadStateChange).toHaveBeenCalled()
      })
    })
  })
})
