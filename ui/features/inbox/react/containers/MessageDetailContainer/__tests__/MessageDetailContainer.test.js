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
import {ApolloProvider} from 'react-apollo'
import {handlers} from '../../../../graphql/mswHandlers'
import {MessageDetailContainer} from '../MessageDetailContainer'
import {Conversation} from '../../../../graphql/Conversation'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import React from 'react'
import waitForApolloLoading from '../../../../util/waitForApolloLoading'
import {responsiveQuerySizes} from '../../../../util/utils'
import {render, fireEvent} from '@testing-library/react'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn()
}))
describe('MessageDetailContainer', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })

    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'}
    }))
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const mockConversation = Conversation.mock()
  const setup = overrideProps => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MessageDetailContainer
            conversation={mockConversation}
            onReply={jest.fn()}
            onReplyAll={jest.fn()}
            onDelete={jest.fn()}
            {...overrideProps}
          />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  describe('rendering', () => {
    it('should render', () => {
      const container = setup()
      expect(container).toBeTruthy()
    })

    it('should render conversation information correctly', async () => {
      const container = setup()
      expect(container.getByText('Loading Conversation Messages')).toBeInTheDocument()
      await waitForApolloLoading()

      expect(await container.findByTestId('message-detail-header-desktop')).toBeInTheDocument()
      expect(
        await container.findByText(mockConversation.conversationMessagesConnection.nodes[1].body)
      ).toBeInTheDocument()
    })
  })

  describe('function inputs', () => {
    it('should delete with correct conversation ID', async () => {
      const mockConvoDelete = jest.fn()
      const container = setup({onDelete: mockConvoDelete})
      await waitForApolloLoading()

      const moreOptionsButton = await container.findByTestId('more-options')
      fireEvent.click(moreOptionsButton)
      fireEvent.click(container.getByText('Delete'))
      expect(mockConvoDelete).toHaveBeenCalledWith([mockConversation._id])
    })

    it('should reply with correct message', async () => {
      const mockOnReply = jest.fn()
      const container = setup({onReply: mockOnReply})
      await waitForApolloLoading()

      const replyButtons = await container.findAllByTestId('message-reply')
      fireEvent.click(replyButtons[1])
      expect(mockOnReply).toHaveBeenCalledWith(
        mockConversation.conversationMessagesConnection.nodes[1]
      )
    })

    it('should reply all with correct message', async () => {
      const mockOnReplyAll = jest.fn()
      const container = setup({onReplyAll: mockOnReplyAll})
      await waitForApolloLoading()

      const moreOptionsButtons = await container.findAllByTestId('message-more-options')
      fireEvent.click(moreOptionsButtons[1])
      fireEvent.click(container.getByText('Reply All'))
      expect(mockOnReplyAll).toHaveBeenCalledWith(
        mockConversation.conversationMessagesConnection.nodes[1]
      )
    })
  })
})
