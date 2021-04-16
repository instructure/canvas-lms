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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from 'react-apollo'
import DiscussionTopicManager from '../DiscussionTopicManager'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {handlers} from '../../graphql/mswHandlers'
import {mswClient} from '../../../../shared/msw/mswClient'
import {mswServer} from '../../../../shared/msw/mswServer'
import React from 'react'

describe('DiscussionsFullPage', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  beforeEach(() => {
    mswClient.cache.reset()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const setup = () => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <DiscussionTopicManager discussionTopicId={1} />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  it('should render', () => {
    const {container} = setup()
    expect(container).toBeTruthy()
  })

  describe('discussion entries', () => {
    it('should render', async () => {
      const container = setup()
      expect(await container.findByText('This is the parent reply')).toBeInTheDocument()
      expect(container.queryByText('This is the child reply')).toBeNull()

      const expandButton = container.getByTestId('expand-button')
      fireEvent.click(expandButton)

      expect(await container.findByText('This is the child reply')).toBeInTheDocument()
    })

    it('should allow deleting entries', async () => {
      window.confirm = jest.fn(() => true)
      const container = setup()

      const actionsButton = await container.findByTestId('thread-actions-menu')
      fireEvent.click(actionsButton)

      const deleteButton = container.getByText('Delete')
      fireEvent.click(deleteButton)

      expect(await container.findByText('Deleted by Matthew Lemon')).toBeInTheDocument()
    })

    it('toggles an entries read state when the Mark as Read/Unread is clicked', async () => {
      const container = setup()
      const actionsButton = await container.findByTestId('thread-actions-menu')

      expect(container.queryByTestId('is-unread')).toBeNull()
      fireEvent.click(actionsButton)
      fireEvent.click(container.getByTestId('markAsUnread'))
      expect(await container.findByTestId('is-unread')).toBeInTheDocument()

      fireEvent.click(actionsButton)
      fireEvent.click(container.getByTestId('markAsRead'))
      await waitFor(() => expect(container.queryByTestId('is-unread')).not.toBeInTheDocument())
    })
  })

  describe('discussion topic', () => {
    it('should render', async () => {
      const container = setup()

      await waitFor(() => expect(container.getAllByText('Matthew Lemon')).toBeTruthy())
      expect(await container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
    })

    it('toggles a topics subscribed state when subscribed is clicked', async () => {
      const container = setup()
      await waitFor(() =>
        expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
      )
      const actionsButton = container.getByText('Subscribed')
      fireEvent.click(actionsButton)
      expect(await container.findByText('Unsubscribed')).toBeInTheDocument()
      fireEvent.click(actionsButton)
      expect(await container.findByText('Subscribed')).toBeInTheDocument()
    })

    it('renders a readonly publish button if canUnpublish is false', async () => {
      const container = setup()
      await waitFor(() =>
        expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
      )
      expect(await container.findByText('Published')).toBeInTheDocument()
      expect(
        await container.getByText('Published').closest('button').hasAttribute('disabled')
      ).toBeTruthy()
    })
  })
})
