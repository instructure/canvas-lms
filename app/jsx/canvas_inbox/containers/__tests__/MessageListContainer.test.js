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
import MessageListContainer from '../MessageListContainer'
import {createCache} from '../../../canvas-apollo'
import {CONVERSATIONS_QUERY} from '../../Queries'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import {mockQuery} from '../../mocks'
import waitForApolloLoading from '../../helpers/waitForApolloLoading'

const createGraphqlMocks = () => {
  const mocks = [
    {
      request: {
        query: CONVERSATIONS_QUERY,
        variables: {
          userID: '1',
          scope: 'inbox',
        },
        overrides: {
          Node: {
            __typename: 'User',
          },
        },
      },
    },
    {
      request: {
        query: CONVERSATIONS_QUERY,
        variables: {
          userID: '1',
          scope: 'inbox',
          course: 'course_123',
        },
        overrides: {
          Node: {
            __typename: 'User',
          },
          Conversation: () => ({
            _id: '1a',
            contextType: 'context',
            contextId: 2,
            contextName: 'Context Name',
            subject: 'Second Subject',
            updateAt: new Date(),
            conversationMessageConnections: [{}],
            conversationParticipantsConnection: [{}],
          }),
        },
      },
    },
    {
      request: {
        query: CONVERSATIONS_QUERY,
        variables: {
          userID: '1',
          scope: 'sent',
        },
        overrides: {
          Node: {
            __typename: 'User',
          },
          Conversation: () => ({
            _id: '1a',
            contextType: 'context',
            contextId: 2,
            contextName: 'Context Name',
            subject: 'Second Subject',
            updateAt: new Date(),
            conversationMessageConnections: [{}],
            conversationParticipantsConnection: [{}],
          }),
        },
      },
    },
  ]

  const mockResults = Promise.all(
    mocks.map(async (m) => {
      const result = await mockQuery(m.request.query, m.request.overrides, m.request.variables)
      return {
        request: {query: m.request.query, variables: m.request.variables},
        result,
      }
    })
  )
  return mockResults
}

const setup = async (messageListContainerProps) => {
  const mocks = await createGraphqlMocks()
  return render(
    <MockedProvider mocks={mocks} cache={createCache()}>
      <MessageListContainer {...messageListContainerProps} />
    </MockedProvider>
  )
}

describe('MessageListContainer', () => {
  beforeEach(() => {
    window.ENV = {
      current_user_id: 1,
    }
  })

  describe('converation_query', () => {
    it('should render query when successful', async () => {
      const component = await setup()
      expect(component).toBeTruthy()
    })

    it('should change list of messages when scope changes', async () => {
      const component = await setup()

      await waitForApolloLoading()

      let messages = await component.queryAllByText('Mock Subject')
      expect(messages.length).toBe(2)

      component.rerender(
        <MockedProvider mocks={await createGraphqlMocks()}>
          <MessageListContainer scope="sent" />
        </MockedProvider>
      )

      await waitForApolloLoading()

      messages = await component.queryByText('Mock Subject')
      expect(messages).toBeNull()
    })

    it('should change list of messaes when course and scope changes', async () => {
      const component = await setup()

      await waitForApolloLoading()

      let messages = await component.queryAllByText('Mock Subject')
      expect(messages.length).toBe(2)

      component.rerender(
        <MockedProvider mocks={await createGraphqlMocks()}>
          <MessageListContainer course="course_123" />
        </MockedProvider>
      )

      await waitForApolloLoading()

      messages = await component.queryByText('Mock Subject')
      expect(messages).toBeNull()
    })
  })

  describe('Selected Messages', () => {
    it('should track when messages are clicked', async () => {
      const mock = jest.fn()
      const messageList = await setup({
        onSelectMessage: mock,
      })

      await waitForApolloLoading()

      const checkboxes = await messageList.findAllByText('not selected')

      fireEvent(
        checkboxes[0],
        new MouseEvent('click', {
          bubbles: true,
          cancelable: true,
        })
      )

      expect(mock.mock.calls.length).toBe(1)
    })
  })
})
