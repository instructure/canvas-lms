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
import Navigation from '../Navigation'

const unreadComponent = jest.fn(() => <></>)

describe('GlobalNavigation', () => {
  beforeEach(() => {
    unreadComponent.mockClear()
    window.ENV.current_user_id = 10
    window.ENV.current_user_disabled_inbox = false
  })

  it('renders', () => {
    expect(() => render(<Navigation unreadComponent={unreadComponent} />)).not.toThrow()
  })

  describe('inbox unread badge', () => {
    it('renders the inbox unread component', () => {
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(1)
      expect(unreadComponent.mock.calls[0][0].dataUrl).toBe('/api/v1/conversations/unread_count')
    })

    it('does not render the inbox unread component when user has opted out of notifications', () => {
      ENV.current_user_disabled_inbox = true
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).not.toHaveBeenCalled()
    })
  })
})
