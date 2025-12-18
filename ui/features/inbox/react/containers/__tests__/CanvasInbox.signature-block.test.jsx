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

import {render, fireEvent} from '@testing-library/react'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from '@apollo/client'

import {mswClient} from '../../../../../shared/msw/mswClient'
import {setupServer} from 'msw/node'
import {handlers, inboxSettingsHandlers} from '../../../graphql/mswHandlers'
import {responsiveQuerySizes} from '../../../util/utils'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import React from 'react'
import CanvasInbox from '../CanvasInbox'

vi.mock('../../../util/utils', async importOriginal => {
  const actual = await importOriginal()
  return {
    ...actual,
    responsiveQuerySizes: vi.fn(),
  }
})

describe('CanvasInbox App Container - Inbox Signature Block Settings', () => {
  const server = setupServer(...handlers.concat(inboxSettingsHandlers()))

  beforeAll(() => {
    server.listen()
    window.matchMedia = vi.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
      }
    })

    // Responsive Query Mock Default
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'},
    }))
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    window.ENV = {}
  })

  beforeEach(() => {
    mswClient.cache.reset()
    window.location.hash = ''
    window.ENV = {
      current_user_id: '9',
      current_user: {
        id: '9',
      },
      CONVERSATIONS: {
        MAX_GROUP_CONVERSATION_SIZE: 100,
      },
    }
  })

  const setup = () => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess: vi.fn()}}>
          <CanvasInbox breakpoints={{desktopOnly: true}} />
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )
  }

  it('should display Inbox Settings in header', () => {
    window.ENV.CONVERSATIONS.INBOX_SIGNATURE_BLOCK_ENABLED = true
    const {getByTestId} = setup()
    expect(getByTestId('inbox-settings-in-header')).toBeInTheDocument()
  })

  it('should redirect to inbox when submission_comments and click on Compose button', async () => {
    window.ENV.CONVERSATIONS.INBOX_SIGNATURE_BLOCK_ENABLED = true
    const {findByText} = setup()
    await waitForApolloLoading()
    window.location.hash = '#filter=type=submission_comments=randomstring'
    const composeButton = await findByText('Compose')
    fireEvent.click(composeButton)
    await waitForApolloLoading()
    expect(window.location.hash).toBe('#filter=type=inbox')
  })
})
