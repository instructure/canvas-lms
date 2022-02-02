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
import CanvasInbox from '../CanvasInbox'
import {ApolloProvider} from 'react-apollo'
import React from 'react'
import {render, fireEvent, waitFor} from '@testing-library/react'
import {responsiveQuerySizes} from '../../../util/utils'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import {handlers} from '../../../graphql/mswHandlers'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {graphql} from 'msw'
import {ConversationParticipant} from '../../../graphql/ConversationParticipant'
import {Conversation} from '../../../graphql/Conversation'

jest.mock('../../../util/utils', () => ({
  ...jest.requireActual('../../../util/utils'),
  responsiveQuerySizes: jest.fn()
}))

describe('CanvasInbox Full Page', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
    window.ENV = {
      current_user: {
        id: '9'
      }
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

    // Repsonsive Query Mock Default
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'}
    }))
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
          <CanvasInbox />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  test('toggles between inbox and sent scopes', async () => {
    const container = setup()
    await waitForApolloLoading()
    const conversationNode = await container.findByTestId('conversation')
    expect(conversationNode).toHaveTextContent('this is a message for the inbox')

    const mailboxDropdown = await container.findByLabelText('Mailbox Selection')
    fireEvent.click(mailboxDropdown)
    await waitForApolloLoading()

    const option = await container.findByText('Sent')

    expect(option).toBeTruthy()

    fireEvent.click(option)

    await waitForApolloLoading()

    const sentConversationNodes = await container.findAllByTestId('conversation')
    expect(sentConversationNodes[0]).toHaveTextContent('this is the first reply message')
    expect(sentConversationNodes[1]).toHaveTextContent('this is the second reply message')
  })

  it('renders the conversation messages', async () => {
    const container = setup()

    const conversation = await container.findByTestId('conversationListItem-Checkbox')
    fireEvent.click(conversation)

    expect(await container.findByText('this is the first reply message')).toBeInTheDocument()
    expect(await container.findByText('this is a reply all')).toBeInTheDocument()
    expect(await container.findByText('testing 123')).toBeInTheDocument()
  })

  // TODO: will be fixed with VICE-2077
  it.skip('should change the read state of a conversation', async () => {
    const container = setup()
    const conversation = await container.findByTestId('conversationListItem-Checkbox')
    fireEvent.click(conversation)
    await container.findByText('Watch out for that Magneto guy')
    expect(container.queryByTestId('unread-badge')).toBeTruthy()
    const settings = await container.findByTestId('settings')
    fireEvent.click(settings)
    const markAsReadButton = await container.findByText('Mark as read')
    fireEvent.click(markAsReadButton)
    expect(container.queryByTestId('unread-badge')).toBeFalsy()
  })

  it('Successfully star selected conversation', async () => {
    const {findAllByTestId, findByTestId, getByText} = setup()

    const checkboxes = await findAllByTestId('conversationListItem-Checkbox')
    expect(checkboxes.length).toBe(1)
    fireEvent.click(checkboxes[0])

    const settingsCog = await findByTestId('settings')
    fireEvent.click(settingsCog)

    const star = getByText('Star')
    fireEvent.click(star)

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The conversation has been successfully starred.')
    )
  })

  it('Successfully star selected conversations', async () => {
    server.use(
      graphql.query('GetConversationsQuery', (req, res, ctx) => {
        const data = {
          legacyNode: {
            _id: '9',
            id: 'VXNlci05',
            conversationsConnection: {
              nodes: [
                {
                  ...ConversationParticipant.mock({_id: 251}),
                  conversation: Conversation.mock()
                },
                {
                  ...ConversationParticipant.mock({_id: 252}),
                  conversation: Conversation.mock()
                }
              ],
              __typename: 'ConversationParticipantConnection'
            },
            __typename: 'User'
          }
        }

        return res.once(ctx.data(data))
      })
    )

    const {findAllByTestId, findByTestId, getByText} = setup()

    const checkboxes = await findAllByTestId('conversationListItem-Checkbox')
    expect(checkboxes.length).toBe(2)
    fireEvent.click(checkboxes[0])
    fireEvent.click(checkboxes[1])

    const settingsCog = await findByTestId('settings')
    fireEvent.click(settingsCog)

    const star = getByText('Star')
    fireEvent.click(star)

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The conversations has been successfully starred.')
    )
  })

  it('should trigger confirm when deleting', async () => {
    window.confirm = jest.fn(() => true)
    const container = setup()

    const conversation = await container.findByTestId('conversationListItem-Checkbox')
    fireEvent.click(conversation)

    const deleteBtn = await container.findByTestId('delete')
    fireEvent.click(deleteBtn)
    expect(window.confirm).toHaveBeenCalled()
  })
})
