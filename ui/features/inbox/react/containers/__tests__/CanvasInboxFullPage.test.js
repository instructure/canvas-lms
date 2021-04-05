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
import {mswServer} from '../../../graphql/mswServer'
import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import {mswClient} from '../../../graphql/mswClient'
import waitForApolloLoading from '../../../util/waitForApolloLoading'

describe('CanvasInbox Full Page', () => {
  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    mswServer.listen()
  })

  afterEach(() => {
    mswServer.resetHandlers()
  })

  afterAll(() => {
    mswServer.close()
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
    const container = await setup()
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
})
