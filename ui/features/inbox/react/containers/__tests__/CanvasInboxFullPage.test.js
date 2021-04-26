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
import {render, fireEvent} from '@testing-library/react'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import {handlers} from '../../../graphql/mswHandlers'
import waitForApolloLoading from '../../../util/waitForApolloLoading'

describe('CanvasInbox Full Page', () => {
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

  const setup = () => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
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

    const conversation = await container.findByTestId('messageListItem-Checkbox')
    fireEvent.click(conversation)

    expect(await container.findByText('Watch out for that Magneto guy')).toBeInTheDocument()
    expect(
      await container.findByText('Wolverine is not so bad when you get to know him')
    ).toBeInTheDocument()
  })
})
