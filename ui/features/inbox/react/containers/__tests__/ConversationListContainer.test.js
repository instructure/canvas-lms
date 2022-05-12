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

import {ApolloProvider} from 'react-apollo'
import ConversationListContainer from '../ConversationListContainer'
import {handlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import React from 'react'
import {render, fireEvent, waitFor, screen} from '@testing-library/react'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {responsiveQuerySizes} from '../../../util/utils'

jest.mock('../../../util/utils', () => ({
  ...jest.requireActual('../../../util/utils'),
  responsiveQuerySizes: jest.fn()
}))

describe('ConversationListContainer', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    // Add appropriate mocks for responsive
    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })

    // Repsonsive Query Mock Default
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

  beforeEach(() => {
    window.ENV = {
      current_user_id: 1
    }
  })

  const setup = conversationListContainerProps => {
    return render(
      <ApolloProvider client={mswClient}>
        <ConversationListContainer {...conversationListContainerProps} />
      </ApolloProvider>
    )
  }

  describe('conversation_query', () => {
    it('should render query when successful', async () => {
      const component = setup()
      expect(component.container).toBeTruthy()
    })

    it('should change list of conversations when scope changes', async () => {
      const component = setup()

      expect(await component.findByText('This is an inbox conversation')).toBeInTheDocument()

      component.rerender(
        <ApolloProvider client={mswClient}>
          <ConversationListContainer scope="sent" />
        </ApolloProvider>
      )

      await waitFor(() =>
        expect(component.queryByText('This is an inbox conversation')).not.toBeInTheDocument()
      )
    })

    it('should change list of conversations when course and scope changes', async () => {
      const component = setup()

      component.rerender(
        <ApolloProvider client={mswClient}>
          <ConversationListContainer scope="inbox" />
        </ApolloProvider>
      )

      await waitFor(() =>
        expect(component.queryByText('This is an inbox conversation')).toBeInTheDocument()
      )

      component.rerender(
        <ApolloProvider client={mswClient}>
          <ConversationListContainer course="course_123" />
        </ApolloProvider>
      )

      await waitFor(() =>
        expect(component.queryByText('This is an inbox conversation')).not.toBeInTheDocument()
      )
    })
  })

  describe('Selected Conversations', () => {
    beforeEach(() => {
      window.document.getSelection = () => {
        return {
          removeAllRanges: () => {}
        }
      }
    })
    it('should track when conversations are clicked', async () => {
      const mock = jest.fn()
      const conversationList = await setup({
        onSelectConversation: mock
      })

      await waitForApolloLoading()

      const checkboxes = await conversationList.findAllByText('not selected')

      fireEvent(
        checkboxes[0],
        new MouseEvent('click', {
          bubbles: true,
          cancelable: true
        })
      )

      expect(mock.mock.calls.length).toBe(3)
    })

    it('should be able to select range of conversations ASC', async () => {
      const mock = jest.fn()
      const conversationList = await setup({
        onSelectConversation: mock,
        scope: 'multipleConversations'
      })
      await waitForApolloLoading()

      const conversations = await conversationList.findAllByTestId('conversationListItem-Item')
      fireEvent.click(conversations[0])
      fireEvent.click(conversations[2], {
        shiftKey: true
      })
      const checkboxes = await conversationList.findAllByTestId('conversationListItem-Checkbox')
      expect(checkboxes.filter(c => c.checked === true).length).toBe(3)
    })

    it('should be able to select range of conversations DESC', async () => {
      const mock = jest.fn()
      const conversationList = await setup({
        onSelectConversation: mock,
        scope: 'multipleConversations'
      })
      await waitForApolloLoading()

      const conversations = await conversationList.findAllByTestId('conversationListItem-Item')
      fireEvent.click(conversations[2])
      fireEvent.click(conversations[0], {
        shiftKey: true
      })
      const checkboxes = await conversationList.findAllByTestId('conversationListItem-Checkbox')
      expect(checkboxes.filter(c => c.checked === true).length).toBe(3)
    })
  })

  describe('responsiveness', () => {
    describe('tablet', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          tablet: {maxWidth: '67'}
        }))
      })

      it('should emit correct test id for tablet', async () => {
        const component = setup()
        expect(component.container).toBeTruthy()
        const listItem = await component.findByTestId('list-items-tablet')
        expect(listItem).toBeTruthy()
      })
    })

    describe('desktop', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          desktop: {minWidth: '768'}
        }))
      })

      it('should emit correct test id for desktop', async () => {
        const component = setup()
        expect(component.container).toBeTruthy()
        const listItem = await screen.findByTestId('list-items-desktop')
        expect(listItem).toBeTruthy()
      })
    })
  })
})
