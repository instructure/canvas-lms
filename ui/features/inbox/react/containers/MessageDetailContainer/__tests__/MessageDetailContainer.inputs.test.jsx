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
import {mswClient} from '@canvas/msw/mswClient'
import {setupServer} from 'msw/node'
import React from 'react'
import waitForApolloLoading from '../../../../util/waitForApolloLoading'
import {responsiveQuerySizes} from '../../../../util/utils'
import {render, fireEvent, waitFor, waitForElementToBeRemoved} from '@testing-library/react'
import {
  ConversationContext,
  CONVERSATION_ID_WHERE_CAN_REPLY_IS_FALSE,
} from '../../../../util/constants'

vi.mock('../../../../util/utils', async () => ({
  ...(await vi.importActual('../../../../util/utils')),
  responsiveQuerySizes: vi.fn(),
}))
describe('MessageDetailContainer', () => {
  const server = setupServer(...handlers)
  beforeAll(() => {
    server.listen()

    window.matchMedia = vi.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
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
    onReply = vi.fn(),
    onReplyAll = vi.fn(),
    onDelete = vi.fn(),
    onForward = vi.fn(),
    onReadStateChange = vi.fn(),
    setOnSuccess = vi.fn(),
    setCanReply = vi.fn(),
    overrideProps = {},
  } = {}) =>
    render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess}}>
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

  describe('conversation messages', () => {
    const mockConversation = Conversation.mock()

    describe('function inputs', () => {
      it('should delete with correct conversation ID', async () => {
        const mockConvoDelete = vi.fn()
        const container = setup({onDelete: mockConvoDelete})
        await waitForApolloLoading()

        const moreOptionsButton = await container.findByTestId('more-options')
        fireEvent.click(moreOptionsButton)
        fireEvent.click(container.getByText('Delete'))
        expect(mockConvoDelete).toHaveBeenCalledWith([mockConversation._id])
      })

      it('should reply with correct message', async () => {
        const mockOnReply = vi.fn()
        const container = setup({onReply: mockOnReply})
        await waitForApolloLoading()

        const replyButtons = await container.findAllByTestId('message-reply')
        fireEvent.click(replyButtons[1])
        expect(mockOnReply.mock.calls[0][0]._id).toBe(
          mockConversation.conversationMessagesConnection.nodes[1]._id,
        )
      })

      it('should forward with correct message', async () => {
        const mockOnForward = vi.fn()
        const container = setup({onForward: mockOnForward})
        await waitForApolloLoading()

        const moreOptionsButtons = await container.findAllByTestId('message-more-options')
        fireEvent.click(moreOptionsButtons[1])
        fireEvent.click(container.getByText('Forward'))
        expect(mockOnForward.mock.calls[0][0]._id).toBe(
          mockConversation.conversationMessagesConnection.nodes[1]._id,
        )
      })

      it('should reply all with correct message', async () => {
        const mockOnReplyAll = vi.fn()
        const container = setup({onReplyAll: mockOnReplyAll})
        await waitForApolloLoading()

        const moreOptionsButtons = await container.findAllByTestId('message-more-options')
        fireEvent.click(moreOptionsButtons[1])
        fireEvent.click(container.getByText('Reply All'))
        expect(mockOnReplyAll.mock.calls[0][0]._id).toBe(
          mockConversation.conversationMessagesConnection.nodes[1]._id,
        )
      })

      it('should mark loaded conversation as read', async () => {
        const mockReadStateChange = vi.fn()
        const container = setup({
          conversation: {
            ...Conversation.mock(),
            workflowState: 'unread',
          },
          onReadStateChange: mockReadStateChange,
        })
        // wait for query to load
        await container.findAllByTestId('message-more-options')

        await waitForApolloLoading()
        expect(mockReadStateChange).toHaveBeenCalled()
      })
    })
  })
})
