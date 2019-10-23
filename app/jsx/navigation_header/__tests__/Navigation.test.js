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
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import Navigation from 'jsx/navigation_header/Navigation'
import waitForExpect from 'wait-for-expect'
describe('GlobalNavigation', () => {
  let componentHolder, $inbox_data
  function renderComponent() {
    ReactDOM.render(<Navigation />, componentHolder)
  }
  beforeEach(() => {
    fetch.resetMocks()
    componentHolder = document.createElement('div')
    document.body.appendChild(componentHolder)
    // Need to setup the global nav stuff we are testing
    $inbox_data = $(`<ul>
    <li class="menu-item ic-app-header__menu-list-item--active">
      <a
        id="global_nav_dashboard_link"
        href="/"
        class"ic-app-header__menu-list-link"
      >
        <div class="menu-item-icon-container">
          Dashboard
        </div>
      </a>
    </li>
    <li class="menu-item">
      <a
        id="global_nav_conversations_link"
        href="/conversations"
        class="ic-app-header__menu-list-link"
      >
        <div class="menu-item-icon-container">
          <span class="menu-item__badge" style="display: none">0</span>
        </div>
      </a>
    </li>
  </ul>
  `).appendTo(document.body)
    window.ENV.current_user_id = 10
    ENV.current_user_disabled_inbox = false
  })
  afterEach(() => {
    ReactDOM.unmountComponentAtNode(componentHolder)
    componentHolder.remove()
    $inbox_data.remove()
  })

  it('renders', () => {
    fetch.mockResponse(JSON.stringify({unread_count: 0}))
    expect(() => renderComponent()).not.toThrow()
  })

  it('shows the inbox badge when necessary', async () => {
    fetch.mockResponse(JSON.stringify({unread_count: 12}))
    renderComponent()
    let $badge
    await waitForExpect(() => {
      $badge = $('#global_nav_conversations_link').find('.menu-item__badge')
      expect($badge.text()).toBe('12 unread messages12')
    })
    expect($badge.css('display')).toBe('')
  })

  it('does not show the inbox badge when the user has opted out of notifications', async () => {
    ENV.current_user_disabled_inbox = true
    renderComponent()
    let $badge
    await waitForExpect(() => {
      $badge = $('#global_nav_conversations_link').find('.menu-item__badge')
      expect($badge.text()).toBe('0')
    })
    expect($badge.css('display')).toBe('none')
  })

  it('adds aria-current to active menu item', () => {
    fetch.mockResponse(JSON.stringify({unread_count: 0}))
    renderComponent()
    const activeItems = document.querySelectorAll('.ic-app-header__menu-list-item--active')
    expect(activeItems.length).toBe(1)
    const currentItems = document.querySelectorAll('[aria-current="page"]')
    expect(currentItems.length).toBe(1)
    expect(currentItems[0]).toBe(activeItems[0])
  })
})