// Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent, waitFor} from '@testing-library/react'
import MobileNavigation from '../MobileNavigation'

describe('MobileNavigation', () => {
  function navComponent() {
    return {
      ensureLoaded: () => {},
      state: {
        unreadInboxCount: 4242,
        unreadSharesCount: 1234,
        accountsAreLoaded: true,
        accounts: [{id: '1', name: 'account'}],
        coursesAreLoaded: true,
        courses: [{id: '1', name: 'course', enrollment_term_id: 2, term: {name: 'term'}}],
        groupsAreLoaded: true,
        groups: [{id: '1', name: 'group'}],
        profileAreLoaded: true,
        profile: [{id: '1', html_url: '/foo', label: 'foo'}],
        helpAreLoaded: false,
        help: [],
        historyAreLoaded: false
      }
    }
  }

  it('renders the inbox badge based on incoming state', async () => {
    const nav = navComponent()
    const hamburgerMenu = document.createElement('div')
    hamburgerMenu.setAttribute('class', 'mobile-header-hamburger')
    document.body.appendChild(hamburgerMenu)
    const {findByText, queryByText} = render(<MobileNavigation DesktopNavComponent={nav} />)
    fireEvent.click(hamburgerMenu)
    await waitFor(() => {
      expect(queryByText('Loading ...')).not.toBeInTheDocument()
    })
    const count = await findByText(nav.state.unreadInboxCount.toString())
    expect(count).toBeInTheDocument()
  })
})
