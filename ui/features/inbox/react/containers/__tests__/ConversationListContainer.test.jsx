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
  responsiveQuerySizes: jest.fn(),
}))

describe('ConversationListContainer', () => {
  const server = mswServer(handlers)
  const getConversationsQuery = (scope, course) => {
    const response = handlers[0].resolver(
      {
        variables: {
          scope,
          course,
        },
      },
      res => {
        return {...res}
      },
      {
        data: data => {
          return {data}
        },
      }
    )
    return JSON.parse(response.body.toString())
  }

  beforeAll(() => {
    server.listen()

    // Add appropriate mocks for responsive
    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })

    // Repsonsive Query Mock Default
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

  beforeEach(() => {
    window.ENV = {
      current_user_id: 1,
    }
  })

  const setup = conversationListContainerProps => {
    const conversationsQuery = {data: getConversationsQuery().data, loading: false}
    const submissionCommentsQuery = {data: null, loading: false}
    return render(
      <ApolloProvider client={mswClient}>
        <ConversationListContainer
          conversationsQuery={conversationsQuery}
          submissionCommentsQuery={submissionCommentsQuery}
          {...conversationListContainerProps}
        />
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

      // Change scope
      const scope = 'sent'
      const data = getConversationsQuery(scope).data
      const conversationsQuery = {data, loading: false}
      const submissionCommentsQuery = {data: null, loading: false}

      component.rerender(
        <ApolloProvider client={mswClient}>
          <ConversationListContainer
            scope={scope}
            conversationsQuery={conversationsQuery}
            submissionCommentsQuery={submissionCommentsQuery}
          />
        </ApolloProvider>
      )

      await waitFor(() =>
        expect(component.queryByText('This is an inbox conversation')).not.toBeInTheDocument()
      )
    })

    it('should not error out when no conversation message is retrieved', async () => {
      const component = setup()
      expect(await component.findByText('This is an inbox conversation')).toBeInTheDocument()

      // Change scope
      const scope = 'null_nodes'
      const conversationsQuery = {data: getConversationsQuery(scope).data, loading: false}
      const submissionCommentsQuery = {data: null, loading: false}

      component.rerender(
        <ApolloProvider client={mswClient}>
          <ConversationListContainer
            scope={scope}
            conversationsQuery={conversationsQuery}
            submissionCommentsQuery={submissionCommentsQuery}
          />
        </ApolloProvider>
      )

      await waitFor(() =>
        expect(component.queryByText('This is an inbox conversation')).not.toBeInTheDocument()
      )
    })

    it('should change list of conversations when course and scope changes', async () => {
      const component = setup()

      // Select scope
      const scope = 'inbox'
      const course = 'course_123'
      const conversationsQuery = {data: getConversationsQuery(scope).data, loading: false}
      const submissionCommentsQuery = {data: null, loading: false}

      component.rerender(
        <ApolloProvider client={mswClient}>
          <ConversationListContainer
            scope={scope}
            conversationsQuery={conversationsQuery}
            submissionCommentsQuery={submissionCommentsQuery}
          />
        </ApolloProvider>
      )

      await waitFor(() =>
        expect(component.queryByText('This is an inbox conversation')).toBeInTheDocument()
      )

      // Select course
      conversationsQuery.data = getConversationsQuery(scope, course).data

      component.rerender(
        <ApolloProvider client={mswClient}>
          <ConversationListContainer
            scope={scope}
            conversationsQuery={conversationsQuery}
            submissionCommentsQuery={submissionCommentsQuery}
          />
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
          removeAllRanges: () => {},
        }
      }
    })
    it('should track when conversations are clicked', async () => {
      const mock = jest.fn()
      const conversationsQuery = {
        data: getConversationsQuery('multipleConversations').data,
        loading: false,
      }

      const conversationList = setup({
        onSelectConversation: mock,
        conversationsQuery,
      })

      await waitForApolloLoading()

      const checkboxes = await conversationList.findAllByText(
        'This is an inbox conversation not selected'
      )
      checkboxes.forEach(checkbox => {
        fireEvent(
          checkbox,
          new MouseEvent('click', {
            bubbles: true,
            cancelable: true,
          })
        )
      })

      expect(mock.mock.calls.length).toBe(4)
    })

    it('should be able to select range of conversations ASC', async () => {
      const conversationsQuery = {
        data: getConversationsQuery('multipleConversations').data,
        loading: false,
      }

      const conversationList = setup({conversationsQuery})
      await waitForApolloLoading()

      const conversations = await conversationList.findAllByTestId('conversationListItem-Item')
      fireEvent.click(conversations[0])
      fireEvent.click(conversations[2], {
        shiftKey: true,
      })
      const checkboxes = await conversationList.findAllByTestId('conversationListItem-Checkbox')
      expect(checkboxes.filter(c => c.checked === true).length).toBe(3)
    })

    it('should be able to select range of conversations DESC', async () => {
      const conversationsQuery = {
        data: getConversationsQuery('multipleConversations').data,
        loading: false,
      }

      const conversationList = setup({conversationsQuery})
      await waitForApolloLoading()

      const conversations = await conversationList.findAllByTestId('conversationListItem-Item')
      fireEvent.click(conversations[2])
      fireEvent.click(conversations[0], {
        shiftKey: true,
      })
      const checkboxes = await conversationList.findAllByTestId('conversationListItem-Checkbox')
      expect(checkboxes.filter(c => c.checked === true).length).toBe(3)
    })
  })

  describe('responsiveness', () => {
    describe('mobile', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          mobile: {maxWidth: '67'},
        }))
      })

      it('should emit correct test id for mobile', async () => {
        const component = setup()
        expect(component.container).toBeTruthy()
        const listItem = await component.findByTestId('list-items-mobile')
        expect(listItem).toBeTruthy()
      })

      it('should correctly truncate for mobile', async () => {
        const component = setup()
        expect(component.container).toBeTruthy()
        const listItem = await component.findByTestId('last-message-content')

        expect(listItem.textContent.length).toBe(93)
      })
    })

    describe('tablet', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          tablet: {maxWidth: '67'},
        }))
      })

      it('should emit correct test id for tablet', async () => {
        const component = setup()
        expect(component.container).toBeTruthy()
        const listItem = await component.findByTestId('list-items-tablet')
        expect(listItem).toBeTruthy()
      })

      it('should correctly truncate for tablet', async () => {
        const component = setup()
        expect(component.container).toBeTruthy()
        const listItem = await component.findByTestId('last-message-content')

        expect(listItem.textContent.length).toBe(43)
      })
    })

    describe('desktop', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          desktop: {minWidth: '768'},
        }))
      })

      it('should emit correct test id for desktop', async () => {
        const component = setup()
        expect(component.container).toBeTruthy()
        const listItem = await screen.findByTestId('list-items-desktop')
        expect(listItem).toBeTruthy()
      })

      it('should correctly truncate for desktop', async () => {
        const component = setup()
        expect(component.container).toBeTruthy()
        const listItem = await component.findByTestId('last-message-content')

        expect(listItem.textContent.length).toBe(43)
      })
    })
  })
})
