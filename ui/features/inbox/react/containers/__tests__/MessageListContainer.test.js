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
import MessageListContainer from '../MessageListContainer'
import {handlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import React from 'react'
import {render, fireEvent, waitFor} from '@testing-library/react'
import waitForApolloLoading from '../../../util/waitForApolloLoading'

describe('MessageListContainer', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
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

  const setup = messageListContainerProps => {
    return render(
      <ApolloProvider client={mswClient}>
        <MessageListContainer {...messageListContainerProps} />
      </ApolloProvider>
    )
  }

  describe('conversation_query', () => {
    it('should render query when successful', async () => {
      const component = setup()
      expect(component.container).toBeTruthy()
    })

    it('should change list of messages when scope changes', async () => {
      const component = setup()

      expect(await component.findByText('This is an inbox conversation')).toBeInTheDocument()

      component.rerender(
        <ApolloProvider client={mswClient}>
          <MessageListContainer scope="sent" />
        </ApolloProvider>
      )

      await waitFor(() =>
        expect(component.queryByText('This is an inbox conversation')).not.toBeInTheDocument()
      )
    })

    it('should change list of messages when course and scope changes', async () => {
      const component = setup()

      expect(await component.findByText('This is an inbox conversation')).toBeInTheDocument()

      component.rerender(
        <ApolloProvider client={mswClient}>
          <MessageListContainer course="course_123" />
        </ApolloProvider>
      )

      await waitFor(() =>
        expect(component.queryByText('This is an inbox conversation')).not.toBeInTheDocument()
      )
    })
  })

  describe('Selected Messages', () => {
    it('should track when messages are clicked', async () => {
      const mock = jest.fn()
      const messageList = await setup({
        onSelectMessage: mock
      })

      await waitForApolloLoading()

      const checkboxes = await messageList.findAllByText('not selected')

      fireEvent(
        checkboxes[0],
        new MouseEvent('click', {
          bubbles: true,
          cancelable: true
        })
      )

      expect(mock.mock.calls.length).toBe(2)
    })
  })
})
