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

import {render, fireEvent, waitFor, within} from '@testing-library/react'
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

jest.mock('../../../util/utils', () => ({
  ...jest.requireActual('../../../util/utils'),
  responsiveQuerySizes: jest.fn(),
}))

describe('CanvasInbox App Container', () => {
  const server = setupServer(...handlers.concat(inboxSettingsHandlers()))

  beforeAll(() => {
    server.listen()
    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })

    // Repsonsive Query Mock Default
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
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <CanvasInbox breakpoints={{desktopOnly: true}} />
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )
  }

  describe('rendering', () => {
    it('should render <CanvasInbox />', () => {
      const container = setup()
      expect(container).toBeTruthy()
    })
  })

  describe('URL routing', () => {
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
        await waitForApolloLoading()

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
    describe('course select', () => {
      it('should set the filter if a valid filter option is given in the initialurl', async () => {
        window.location.hash = '#filter=type=inbox&course=course_195'
        const container = setup()
        await waitForApolloLoading()

        const mailboxDropdown = await container.findByTestId('course-select')
        expect(window.location.hash).toBe('#filter=type=inbox&course=course_195')
        expect(mailboxDropdown.getAttribute('value')).toBe('XavierSchool')
      })
      it('should update filter if url filter value is updated', async () => {
        window.location.hash = '#filter=type=inbox'
        const container = setup()
        await waitForApolloLoading()

        let mailboxDropdown = await container.findByTestId('course-select')
        expect(window.location.hash).toBe('#filter=type=inbox')
        expect(mailboxDropdown.getAttribute('value')).toBe('')

        window.location.hash = '#filter=type=inbox&course=course_195'
        await waitForApolloLoading()

        mailboxDropdown = await container.findByTestId('course-select')
        expect(mailboxDropdown.getAttribute('value')).toBe('XavierSchool')
      })
      it('should update the url correctly if scope filter is changed in UI', async () => {
        const container = setup()
        await waitForApolloLoading()

        expect(window.location.hash).toBe('#filter=type=inbox')

        const courseDropdown = container.getByTestId('course-select')
        await userEvent.click(courseDropdown)
        await waitForApolloLoading()

        const listbox = await container.findByRole('listbox')
        await waitFor(() => within(listbox).getAllByRole('option', {name: /Ipsum/}))
        const options = within(listbox).getAllByRole('option', {name: /Ipsum/})
        expect(options).toHaveLength(4)
        await userEvent.click(options[0])
        await waitForApolloLoading()

        expect(window.location.hash).toBe('#filter=type=inbox&course=course_195')
      })
      it('should remove the courseFilter if the url filter is invalid', async () => {
        const container = setup()
        await waitForApolloLoading()

        window.location.hash = '#filter=type=inbox&course=FAKE_COURSE'
        await waitForApolloLoading()

        const mailboxDropdown = await container.findByTestId('course-select')
        expect(window.location.hash).toBe('#filter=type=inbox')
        expect(mailboxDropdown.getAttribute('value')).toBe('')
      })
      it('should set course select in compose modal to course name when the context id param is in the url', async () => {
        const url = new URL(window.location.href)
        url.hash = '#filter=type=inbox'
        url.search = '?context_id=course_195&user_id=9&user_name=Ally'
        window.history.pushState({}, '', url.toString())

        const container = setup()
        await waitForApolloLoading()

        const courseSelectModal = await container.findByTestId('course-select-modal')
        expect(courseSelectModal.getAttribute('value')).toBe('XavierSchool')
      })
    })
  })

  describe('Inbox Signature Block Settings enabled', () => {
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
    }, 15000)
  })
})
