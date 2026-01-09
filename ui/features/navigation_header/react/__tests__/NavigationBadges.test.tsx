/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {render as testingLibraryRender, screen, act} from '@testing-library/react'
import NavigationBadges from '../NavigationBadges'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeENV from '@canvas/test-utils/fakeENV'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer(
  http.get('/api/v1/users/self/content_shares/unread_count', () =>
    HttpResponse.json({unread_count: 0}),
  ),
  http.get('/api/v1/conversations/unread_count', () => HttpResponse.json({unread_count: '0'})),
  http.get('/api/v1/release_notes/unread_count', () => HttpResponse.json({unread_count: 0})),
)

const render = (children: unknown) =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const unreadComponent = vi.fn(() => <></>)

describe('GlobalNavigation', () => {
  beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    unreadComponent.mockClear()
    fakeENV.setup({
      current_user_id: '10',
      current_user_disabled_inbox: false,
      CAN_VIEW_CONTENT_SHARES: true,
      SETTINGS: {release_notes_badge_disabled: false},
      FEATURES: {embedded_release_notes: true},
    })
  })

  afterEach(() => {
    queryClient.resetQueries()
    fakeENV.teardown()
  })

  it('renders', async () => {
    await act(async () => {
      render(<NavigationBadges />)
    })
  })

  describe('unread badges', () => {
    it('fetches the shares unread count when the user does have permission', async () => {
      await act(async () => {
        render(<NavigationBadges />)
      })

      // Wait for React Query to settle
      await act(async () => {
        await queryClient.invalidateQueries({queryKey: ['unread_count', 'content_shares']})
        await queryClient.refetchQueries({queryKey: ['unread_count', 'content_shares']})
      })

      // Verify the request was made
      expect(window.ENV.CAN_VIEW_CONTENT_SHARES).toBe(true)
    })

    it('does not fetch the shares unread count when the user does not have permission', async () => {
      fakeENV.setup({CAN_VIEW_CONTENT_SHARES: false})
      let shareRequestMade = false
      server.use(
        http.get('/api/v1/users/self/content_shares/unread_count', () => {
          shareRequestMade = true
          return HttpResponse.json({unread_count: 0})
        }),
      )

      await act(async () => {
        render(<NavigationBadges />)
      })

      // Wait for React Query to settle
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
      })

      expect(shareRequestMade).toBe(false)
    })

    it('does not fetch the shares unread count when the user is not logged in', async () => {
      fakeENV.setup({current_user_id: null})
      let shareRequestMade = false
      server.use(
        http.get('/api/v1/users/self/content_shares/unread_count', () => {
          shareRequestMade = true
          return HttpResponse.json({unread_count: 0})
        }),
      )

      await act(async () => {
        render(<NavigationBadges />)
      })

      // Wait for React Query to settle
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
      })

      expect(shareRequestMade).toBe(false)
    })

    it('fetches inbox count when user has not opted out of notifications', async () => {
      let inboxRequestMade = false
      server.use(
        http.get('/api/v1/conversations/unread_count', () => {
          inboxRequestMade = true
          return HttpResponse.json({unread_count: '0'})
        }),
      )

      await act(async () => {
        render(<NavigationBadges />)
      })

      // Wait for React Query to settle
      await act(async () => {
        await queryClient.invalidateQueries({queryKey: ['unread_count', 'conversations']})
        await queryClient.refetchQueries({queryKey: ['unread_count', 'conversations']})
      })

      expect(inboxRequestMade).toBe(true)
    })

    it('does not fetch inbox count when user has opted out of notifications', async () => {
      fakeENV.setup({current_user_disabled_inbox: true})
      let inboxRequestMade = false
      server.use(
        http.get('/api/v1/conversations/unread_count', () => {
          inboxRequestMade = true
          return HttpResponse.json({unread_count: '0'})
        }),
      )

      await act(async () => {
        render(<NavigationBadges />)
      })

      // Wait for React Query to settle
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
      })

      expect(inboxRequestMade).toBe(false)
    })

    it('does not fetch the release notes unread count when user has opted out of notifications', async () => {
      fakeENV.setup({
        current_user_id: '10',
        current_user_disabled_inbox: false,
        CAN_VIEW_CONTENT_SHARES: true,
        SETTINGS: {release_notes_badge_disabled: true},
        FEATURES: {embedded_release_notes: true},
      })
      queryClient.setQueryData(['settings', 'release_notes_badge_disabled'], true)
      let releaseNotesRequestMade = false
      server.use(
        http.get('/api/v1/release_notes/unread_count', () => {
          releaseNotesRequestMade = true
          return HttpResponse.json({unread_count: 0})
        }),
      )

      await act(async () => {
        render(<NavigationBadges />)
      })

      // Wait for React Query to settle
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
      })

      expect(releaseNotesRequestMade).toBe(false)
    })

    it('does not render the release notes badge Portal when badge is disabled', async () => {
      fakeENV.setup({
        current_user_id: '10',
        current_user_disabled_inbox: false,
        CAN_VIEW_CONTENT_SHARES: true,
        SETTINGS: {release_notes_badge_disabled: true},
        FEATURES: {embedded_release_notes: true},
      })
      queryClient.setQueryData(['settings', 'release_notes_badge_disabled'], true)
      queryClient.setQueryData(['unread_count', 'release_notes'], 5)

      await act(async () => {
        render(<NavigationBadges />)
      })

      expect(queryClient.getQueryData(['settings', 'release_notes_badge_disabled'])).toBe(true)
      expect(queryClient.getQueryData(['unread_count', 'release_notes'])).toBe(5)
      expect(screen.queryByText(/unread release notes/i)).not.toBeInTheDocument()
    })

    it('renders the release notes badge Portal when badge is enabled', async () => {
      fakeENV.setup({
        current_user_id: '10',
        current_user_disabled_inbox: false,
        CAN_VIEW_CONTENT_SHARES: true,
        SETTINGS: {release_notes_badge_disabled: false},
        FEATURES: {embedded_release_notes: true},
      })
      queryClient.setQueryData(['settings', 'release_notes_badge_disabled'], false)
      queryClient.setQueryData(['unread_count', 'release_notes'], 3)

      await act(async () => {
        render(<NavigationBadges />)
      })

      expect(queryClient.getQueryData(['unread_count', 'release_notes'])).toBe(3)
      expect(queryClient.getQueryData(['settings', 'release_notes_badge_disabled'])).toBe(false)
      expect(screen.getByText(/3.*unread release notes/i)).toBeInTheDocument()
    })
  })
})
