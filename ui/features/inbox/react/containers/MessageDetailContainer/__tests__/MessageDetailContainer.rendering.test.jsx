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
import {render, fireEvent, waitFor, waitForElementToBeRemoved} from '@testing-library/react'
import {
  ConversationContext,
  CONVERSATION_ID_WHERE_CAN_REPLY_IS_FALSE,
} from '../../../../util/constants'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn(),
}))

describe('MessageDetailContainer', () => {
  const server = mswServer(handlers)

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})

    window.matchMedia = jest.fn().mockImplementation(() => ({
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }))

    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'},
    }))
  })

  beforeEach(() => {
    jest.clearAllMocks()
  })

  afterEach(async () => {
    server.resetHandlers()
    await waitFor(() => expect(mswClient.stop).toBeDefined())
  })

  afterAll(() => {
    server.close()
    jest.restoreAllMocks()
  })

  const setup = async ({
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
  } = {}) => {
    const container = render(
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

    // Wait for loading to complete, handling both cases where loader might or might not be present
    await waitFor(() => {
      const loader = container.queryByTestId('conversation-loader')
      return loader === null
    })
    await waitForApolloLoading()

    return container
  }

  describe('conversation messages', () => {
    const mockConversation = Conversation.mock()

    describe('rendering', () => {
      it('should not render the reply or reply_all option in header if student lacks permission', async () => {
        const container = await setup({
          conversation: {...Conversation.mock({_id: CONVERSATION_ID_WHERE_CAN_REPLY_IS_FALSE})},
        })

        await waitFor(() => {
          expect(container.queryByTestId('message-detail-header-reply-btn')).not.toBeInTheDocument()
          expect(container.queryByTestId('message-reply')).not.toBeInTheDocument()
        })
      })

      it('should render conversation information correctly', async () => {
        const container = await setup()

        await waitFor(() => {
          expect(container.getByTestId('message-detail-header-desktop')).toBeInTheDocument()
          expect(
            container.getByText(mockConversation.conversationMessagesConnection.nodes[1].body),
          ).toBeInTheDocument()
        })
      })

      it('should render (No subject) when subject is empty', async () => {
        const container = await setup({conversation: Conversation.mock({subject: ''})})

        await waitFor(() => {
          expect(container.getByText('(No subject)')).toBeInTheDocument()
        })
      })
    })
  })
})
