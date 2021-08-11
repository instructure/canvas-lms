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

jest.mock('@canvas/rce/RichContentEditor')
jest.mock('../utils', () => ({
  ...jest.requireActual('../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}})
}))

describe('DiscussionsIsolatedView', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    window.ENV = {
      discussion_topic_id: '1',
      course_id: '1',
      isolated_view: true
    }

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })
  })

  beforeEach(() => {
    mswClient.cache.reset()
  })

  afterEach(() => {
    server.resetHandlers()
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const setup = () => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <DiscussionTopicManager discussionTopicId="1" />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  it.skip('should be able to post a reply to an entry', async () => {
    const {findByText, findByTestId, queryByTestId} = setup()

    const replyButton = await findByTestId('threading-toolbar-reply')
    fireEvent.click(replyButton)

    expect(findByText('Thread')).toBeTruthy()

    const doReplyButton = await findByTestId('DiscussionEdit-submit')
    fireEvent.click(doReplyButton)

    await waitFor(() => expect(queryByTestId('DiscussionEdit-container')).not.toBeInTheDocument())

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The discussion entry was successfully created.')
    )
  })

  it('should be able to edit a root entry', async () => {
    const {findByText, findByTestId, findAllByTestId} = setup()

    const expandButton = await findByTestId('expand-button')
    fireEvent.click(expandButton)

    const actionsButtons = await findAllByTestId('thread-actions-menu')
    fireEvent.click(actionsButtons[0]) // Root Entry kebab

    const editButton = await findByText('Edit')
    fireEvent.click(editButton)

    const saveButton = await findByText('Save')
    fireEvent.click(saveButton)

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The reply was successfully updated.')
    )
  })

  it('should not render go to reply button with single character search term', async () => {
    const container = setup()
    await waitFor(() => expect(container.queryByTestId('isolated-view-container')).toBeNull())
    fireEvent.change(await container.findByTestId('search-filter'), {
      target: {value: 'a'}
    })

    await waitFor(() => expect(container.queryByTestId('go-to-reply')).toBeNull())
  })

  it('should open isolated view when go to reply button is clicked', async () => {
    const container = setup()
    await waitFor(() => expect(container.queryByTestId('isolated-view-container')).toBeNull())
    fireEvent.change(await container.findByTestId('search-filter'), {
      target: {value: 'parent'}
    })
    const goToReply = await container.findByTestId('go-to-reply')
    fireEvent.click(goToReply)

    await waitFor(() => expect(container.queryByTestId('isolated-view-container')).not.toBeNull())
  })

  it('should show reply button in isolated view when search term is present', async () => {
    const container = setup()
    fireEvent.change(await container.findByTestId('search-filter'), {
      target: {value: 'parent'}
    })
    const goToReply = await container.findByTestId('go-to-reply')
    fireEvent.click(goToReply)
    await waitFor(() => expect(container.queryByTestId('threading-toolbar-reply')).toBeNull())
  })

  // This isn't a broken test. This functionality is really not working.
  it.skip('go to topic button should clear search term', async () => {
    const container = setup()
    fireEvent.change(await container.findByTestId('search-filter'), {
      target: {value: 'a'}
    })
    const goToReply = await container.findByTestId('go-to-reply')
    fireEvent.click(goToReply)

    const isolatedKabab = await container.findAllByTestId('thread-actions-menu')
    fireEvent.click(isolatedKabab[0])

    await waitFor(() => {
      expect(container.queryByTestId('discussion-topic-container')).toBeNull()
    })
    const goToTopic = await container.findByText('Go To Topic')
    fireEvent.click(goToTopic)

    expect(await container.findByTestId('discussion-topic-container')).toBeTruthy()
  })

  it('should clear input when button is pressed', async () => {
    const container = setup()
    let searchInput = container.findByTestId('search-filter')

    fireEvent.change(await container.findByTestId('search-filter'), {
      target: {value: 'A new Search'}
    })
    let clearSearchButton = container.queryByTestId('clear-search-button')
    searchInput = container.getByLabelText('Search entries or author')
    expect(searchInput.value).toBe('A new Search')
    expect(clearSearchButton).toBeInTheDocument()

    fireEvent.click(clearSearchButton)
    clearSearchButton = container.queryByTestId('clear-search-button')
    searchInput = container.getByLabelText('Search entries or author')
    expect(searchInput.value).toBe('')
    expect(clearSearchButton).toBeNull()
  })
})
