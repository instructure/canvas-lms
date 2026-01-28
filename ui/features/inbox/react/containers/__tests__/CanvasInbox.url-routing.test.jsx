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

import {render, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
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

describe('CanvasInbox App Container - URL Routing', () => {
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

  it('should load default URL as inbox Scope', async () => {
    const container = setup()
    await waitForApolloLoading()
    expect(window.location.hash).toBe('#filter=type=inbox')

    const mailboxDropdown = await container.findByLabelText('Mailbox Selection')
    expect(mailboxDropdown.getAttribute('value')).toBe('Inbox')
  })

  it('should respect the initial loading url hash', async () => {
    window.location.hash = '#filter=type=sent'
    const container = setup()
    await waitForApolloLoading()
    expect(window.location.hash).toBe('#filter=type=sent')

    const mailboxDropdown = await container.findByLabelText('Mailbox Selection')
    expect(mailboxDropdown.getAttribute('value')).toBe('Sent')
  })

  describe('scope select', () => {
    it('should update filter if url filter value is updated', async () => {
      const container = setup()
      await waitForApolloLoading()

      let mailboxDropdown = await container.findByLabelText('Mailbox Selection')
      expect(mailboxDropdown.getAttribute('value')).toBe('Inbox')

      window.location.hash = '#filter=type=archived'
      await waitForApolloLoading()

      mailboxDropdown = await container.findByLabelText('Mailbox Selection')
      expect(mailboxDropdown.getAttribute('value')).toBe('Archived')
    })

    it('should update the url correctly if scope filter is changed in UI', async () => {
      const container = setup()
      await waitForApolloLoading()

      expect(window.location.hash).toBe('#filter=type=inbox')

      const mailboxDropdown = await container.findByLabelText('Mailbox Selection')
      await userEvent.click(mailboxDropdown)

      const listbox = await container.findByRole('listbox')
      const option = within(listbox).getByRole('option', {name: 'Sent'})
      await userEvent.click(option)
      await waitForApolloLoading()

      expect(window.location.hash).toBe('#filter=type=sent')
    })

    it('should not update filter if url filter is invalid', async () => {
      const container = setup()
      await waitForApolloLoading()

      let mailboxDropdown = await container.findByLabelText('Mailbox Selection')
      expect(mailboxDropdown.getAttribute('value')).toBe('Inbox')

      window.location.hash = '#filter=type=FAKEFILTER'
      await waitForApolloLoading()

      mailboxDropdown = await container.findByLabelText('Mailbox Selection')
      expect(mailboxDropdown.getAttribute('value')).toBe('Inbox')
    })
  })

  describe('compose modal URL parameter', () => {
    it('should open compose modal when compose=true parameter is present', async () => {
      const url = new URL(window.location.href)
      url.search = '?compose=true'
      window.history.replaceState({}, '', url.toString())

      const container = setup()
      await waitForApolloLoading()

      const composeModal = await container.findByTestId('compose-modal-desktop')
      expect(composeModal).toBeInTheDocument()
    })

    it('should open compose modal with course pre-selected when compose=true and context_id parameters are present', async () => {
      const url = new URL(window.location.href)
      url.search = '?compose=true&context_id=course_195'
      window.history.replaceState({}, '', url.toString())

      const container = setup()
      await waitForApolloLoading()

      const composeModal = await container.findByTestId('compose-modal-desktop')
      expect(composeModal).toBeInTheDocument()

      const courseSelectModal = await container.findByTestId('course-select-modal')
      expect(courseSelectModal.getAttribute('value')).toBe('XavierSchool')
    })

    it('should not open compose modal when compose parameter is false or missing', async () => {
      const url = new URL(window.location.href)
      url.search = '?compose=false'
      window.history.replaceState({}, '', url.toString())

      const container = setup()
      await waitForApolloLoading()

      const composeModal = container.queryByTestId('compose-modal-desktop')
      expect(composeModal).not.toBeInTheDocument()
    })
  })
})
