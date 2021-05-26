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
import {graphql} from 'msw'
import React from 'react'

jest.mock('@canvas/rce/RichContentEditor')

describe('DiscussionFullPage', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    window.ENV = {
      discussion_topic_id: '1'
    }
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

    it('toggles an entries rating state when the like button is clicked', async () => {
      const container = setup()
      const likeButton = await container.findByTestId('like-button')

      expect(container.queryByText('Like count: 1')).toBeNull()
      fireEvent.click(likeButton)
      await waitFor(() => expect(container.queryByText('Like count: 1')).toBeTruthy())

      fireEvent.click(likeButton)
      await waitFor(() => expect(container.queryByText('Like count: 1')).toBeNull())
    })

    it('updates discussion entry', async () => {
      const {getByTestId, queryByText, findByTestId, queryAllByTestId, getAllByTestId} = setup()
      await waitFor(() => expect(queryByText('This is the parent reply')).toBeInTheDocument())

      const actionsButton = await findByTestId('thread-actions-menu')
      fireEvent.click(actionsButton)
      fireEvent.click(getByTestId('edit'))

      const bodyInput = queryAllByTestId('message-body')[1]
      fireEvent.change(bodyInput, {target: {value: ''}})

      const submitButton = getAllByTestId('DiscussionEdit-submit')[1]
      fireEvent.click(submitButton)

      await waitFor(() => expect(queryByText('This is the parent reply')).not.toBeInTheDocument())
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

  describe('error handling', () => {
    it('should render generic error page when DISCUSSION_QUERY returns null', async () => {
      server.use(
        graphql.query('GetDiscussionQuery', (req, res, ctx) => {
          return res.once(ctx.data({legacyNode: null}))
        })
      )

      const container = setup()
      await waitFor(() => expect(container.getAllByText('Sorry, Something Broke')).toBeTruthy())
    })

    it('should render generic error page when DISCUSSION_QUERY returns errors', async () => {
      server.use(
        graphql.query('GetDiscussionQuery', (req, res, ctx) => {
          return res.once(
            ctx.errors([
              {
                message: 'generic error'
              }
            ])
          )
        })
      )

      const container = setup()
      await waitFor(() => expect(container.getAllByText('Sorry, Something Broke')).toBeTruthy())
    })

    it('renders the dates properly', async () => {
      const container = setup()
      expect(await container.findByText('Nov 23, 2020 6:40pm')).toBeInTheDocument()
      expect(await container.findByText(', last reply Apr 5 7:41pm')).toBeInTheDocument()
    })
  })

  it('should be able to post a reply to the topic', async () => {
    const {getByTestId, findByTestId, queryAllByTestId} = setup()

    const replyButton = await findByTestId('discussion-topic-reply')
    fireEvent.click(replyButton)

    const rce = await findByTestId('DiscussionEdit-container')
    expect(rce.style.display).toBe('')

    const bodyInput = queryAllByTestId('message-body')[0]
    fireEvent.change(bodyInput, {target: {value: 'This is a reply'}})

    expect(bodyInput.value).toEqual('This is a reply')

    const doReplyButton = getByTestId('DiscussionEdit-submit')
    fireEvent.click(doReplyButton)

    expect((await findByTestId('DiscussionEdit-container')).style.display).toBe('none')

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The discussion entry was successfully created.')
    )
  })

  it('should be able to post a reply to an entry', async () => {
    const {findByTestId, findAllByTestId, getAllByTestId} = setup()

    const replyButton = await findByTestId('threading-toolbar-reply')
    fireEvent.click(replyButton)

    const rce = await findAllByTestId('DiscussionEdit-container')
    expect(rce[1].style.display).toBe('')

    const doReplyButton = getAllByTestId('DiscussionEdit-submit')
    fireEvent.click(doReplyButton[1])

    expect((await findAllByTestId('DiscussionEdit-container')).style).toBeFalsy()

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The discussion entry was successfully created.')
    )
  })
})
