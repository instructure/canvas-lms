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
import {render as testingLibraryRender, act} from '@testing-library/react'
import NavigationBadges from '../NavigationBadges'
import {QueryProvider, queryClient} from '@canvas/query'
import fetchMock from 'fetch-mock'

const render = (children: unknown) =>
  testingLibraryRender(<QueryProvider>{children}</QueryProvider>)

const unreadComponent = jest.fn(() => <></>)

describe('GlobalNavigation', () => {
  beforeEach(() => {
    unreadComponent.mockClear()
    window.ENV.current_user_id = '10'
    window.ENV.current_user_disabled_inbox = false
    window.ENV.CAN_VIEW_CONTENT_SHARES = true
    // @ts-expect-error
    window.ENV.SETTINGS = {release_notes_badge_disabled: false}
    window.ENV.FEATURES = {embedded_release_notes: true}

    fetchMock.get('/api/v1/users/self/content_shares/unread_count', {unread_count: 0})
    fetchMock.get('/api/v1/conversations/unread_count', {unread_count: '0'})
    fetchMock.get('/api/v1/release_notes/unread_count', {unread_count: 0})
  })

  afterEach(() => {
    queryClient.resetQueries()
    fetchMock.reset()
  })

  it('renders', async () => {
    await act(async () => {
      render(<NavigationBadges />)
    })
  })

  describe('unread badges', () => {
    it('fetches the shares unread count when the user does have permission', async () => {
      ENV.CAN_VIEW_CONTENT_SHARES = true
      await act(async () => {
        render(<NavigationBadges />)
      })
      expect(
        fetchMock.calls().every(([url]) => url !== '/api/v1/users/self/content_shares/unread_count')
      ).toBe(true)
    })

    it('does not fetch the shares unread count when the user does not have permission', async () => {
      ENV.CAN_VIEW_CONTENT_SHARES = false
      await act(async () => {
        render(<NavigationBadges />)
      })
      expect(
        fetchMock.calls().every(([url]) => url !== '/api/v1/users/self/content_shares/unread_count')
      ).toBe(true)
    })

    it('does not fetch the shares unread count when the user is not logged in', async () => {
      ENV.current_user_id = null
      await act(async () => {
        render(<NavigationBadges />)
      })
      expect(
        fetchMock.calls().every(([url]) => url !== '/api/v1/users/self/content_shares/unread_count')
      ).toBe(true)
    })
    // FOO-4218 - remove or rewrite to remove spies on imports
    it.skip('fetches inbox count when user has not opted out of notifications', async () => {
      ENV.current_user_disabled_inbox = false
      await act(async () => {
        render(<NavigationBadges />)
      })
      expect(fetchMock.calls().some(([url]) => url === '/api/v1/conversations/unread_count')).toBe(
        true
      )
    })
    it('does not fetch inbox count when user has opted out of notifications', async () => {
      ENV.current_user_disabled_inbox = true
      await act(async () => {
        render(<NavigationBadges />)
      })
      expect(fetchMock.calls().every(([url]) => url !== '/api/v1/conversations/unread_count')).toBe(
        true
      )
    })
    it('does not fetch the release notes unread count when user has opted out of notifications', async () => {
      ENV.SETTINGS.release_notes_badge_disabled = true
      queryClient.setQueryData(['settings', 'release_notes_badge_disabled'], true)
      await act(async () => {
        render(<NavigationBadges />)
      })
      expect(fetchMock.calls().every(([url]) => url !== '/api/v1/release_notes/unread_count')).toBe(
        true
      )
    })
  })
})
