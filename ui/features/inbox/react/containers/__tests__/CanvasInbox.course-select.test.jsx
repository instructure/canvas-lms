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

import {render, waitFor, within} from '@testing-library/react'
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

describe('CanvasInbox App Container - Course Select', () => {
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
    mswClient.cache.reset()
    window.history.replaceState({}, '', window.location.pathname)
    window.location.hash = ''
  })

  afterAll(() => {
    server.close()
    window.ENV = {}
  })

  beforeEach(() => {
    mswClient.cache.reset()
    // Clean up URL state from previous tests
    window.history.replaceState({}, '', window.location.pathname)
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

  it('should set the filter if a valid filter option is given in the initial url', async () => {
    window.location.hash = '#filter=type=inbox&course=course_195'
    const container = setup()
    await waitForApolloLoading()

    const mailboxDropdown = await container.findByTestId('course-select')
    expect(window.location.hash).toBe('#filter=type=inbox&course=course_195')
    await waitFor(() => expect(mailboxDropdown.getAttribute('value')).toBe('XavierSchool'))
  })

  it('should update filter if url filter value is updated', async () => {
    window.location.hash = '#filter=type=inbox'
    const container = setup()
    await waitForApolloLoading()

    let mailboxDropdown = await container.findByTestId('course-select')
    expect(window.location.hash).toBe('#filter=type=inbox')
    expect(mailboxDropdown.getAttribute('value')).toBe('All Courses')

    window.location.hash = '#filter=type=inbox&course=course_195'
    await waitForApolloLoading()

    mailboxDropdown = await container.findByTestId('course-select')
    await waitFor(() => expect(mailboxDropdown.getAttribute('value')).toBe('XavierSchool'), {
      timeout: 5000,
    })
  }, 10000)

  it('should update the url correctly if scope filter is changed in UI', async () => {
    const container = setup()
    await waitForApolloLoading()

    expect(window.location.hash).toBe('#filter=type=inbox')

    const courseDropdown = container.getByTestId('course-select')
    await userEvent.click(courseDropdown)

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
    await waitFor(() => expect(window.location.hash).toBe('#filter=type=inbox'), {timeout: 5000})
    expect(mailboxDropdown.getAttribute('value')).toBe('All Courses')
  }, 10000)

  it('should set course select in compose modal to course name when the context id param is in the url', async () => {
    // Set URL params before rendering to ensure the component reads them on mount
    const url = new URL(window.location.href)
    url.hash = '#filter=type=inbox'
    url.search = '?context_id=course_195&user_id=9&user_name=Ally'
    window.history.replaceState({}, '', url.toString())

    const container = setup()
    await waitForApolloLoading()

    // Wait for the compose modal to appear and the course select within it
    const courseSelectModal = await container.findByTestId(
      'course-select-modal',
      {},
      {timeout: 5000},
    )
    await waitFor(() => expect(courseSelectModal.getAttribute('value')).toBe('XavierSchool'))
  })
})
