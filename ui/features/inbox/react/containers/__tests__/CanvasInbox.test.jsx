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
import CanvasInbox from '../CanvasInbox'
import {handlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import {responsiveQuerySizes} from '../../../util/utils'
import waitForApolloLoading from '../../../util/waitForApolloLoading'

jest.mock('../../../util/utils', () => ({
  ...jest.requireActual('../../../util/utils'),
  responsiveQuerySizes: jest.fn(),
}))

describe('CanvasInbox App Container', () => {
  const server = mswServer(handlers)

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
          <CanvasInbox />
        </AlertManagerContext.Provider>
      </ApolloProvider>
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
        fireEvent.click(mailboxDropdown)
        await waitForApolloLoading()

        const option = await container.findByText('Sent')
        fireEvent.click(option)
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

        const courseDropdown = await container.findByTestId('course-select')
        fireEvent.click(courseDropdown)
        await waitForApolloLoading()

        const option = await container.findByText('Ipsum')
        fireEvent.click(option)
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
        const originalLocation = window.location
        delete window.location
        window.location = {
          search: '',
          hash: '',
        }
        window.location.hash = '#filter=type=inbox'
        window.location.search = '?context_id=course_195&user_id=9&user_name=Ally'
        const container = setup()
        await waitForApolloLoading()

        const courseSelectModal = await container.findByTestId('course-select-modal')
        expect(courseSelectModal.getAttribute('value')).toBe('XavierSchool')
        window.location = originalLocation
      })
    })
  })
})
