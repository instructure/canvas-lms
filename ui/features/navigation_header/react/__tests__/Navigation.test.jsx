// Copyright (C) 2015 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
import React from 'react'
import {render} from '@testing-library/react'
import Navigation from '../OldSideNav'

const unreadComponent = jest.fn(() => <></>)

describe('GlobalNavigation', () => {
  beforeEach(() => {
    unreadComponent.mockClear()
    window.ENV.current_user_id = 10
    window.ENV.current_user_disabled_inbox = false
    window.ENV.CAN_VIEW_CONTENT_SHARES = true
    window.ENV.SETTINGS = {release_notes_badge_disabled: false}
    window.ENV.FEATURES = {embedded_release_notes: true}
  })

  it('renders', () => {
    expect(() => render(<Navigation unreadComponent={unreadComponent} />)).not.toThrow()
  })

  describe('unread badges', () => {
    it('renders the shares unread, inbox unread, and release notes unread component', () => {
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(3)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).toEqual(
        expect.arrayContaining([
          '/api/v1/users/self/content_shares/unread_count',
          '/api/v1/conversations/unread_count',
          '/api/v1/release_notes/unread_count',
        ])
      )
    })

    it('does not render the shares unread component when the user does not have permission', () => {
      ENV.CAN_VIEW_CONTENT_SHARES = false
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(2)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).not.toEqual(
        expect.arrayContaining(['/api/v1/users/self/content_shares/unread_count'])
      )
    })

    it('does not render the shares unread component when the user is not logged in', () => {
      ENV.current_user_id = null
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(2)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).not.toEqual(
        expect.arrayContaining(['/api/v1/users/self/content_shares/unread_count'])
      )
    })

    it('does not render the inbox unread component when user has opted out of notifications', () => {
      ENV.current_user_disabled_inbox = true
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(2)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).not.toEqual(expect.arrayContaining(['/api/v1/conversations/unread_count']))
    })

    it('does not render the release notes unread component when user has opted out of notifications', () => {
      ENV.SETTINGS.release_notes_badge_disabled = true
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(2)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).not.toEqual(expect.arrayContaining(['/api/v1/release_notes/unread_count']))
    })
  })
})
