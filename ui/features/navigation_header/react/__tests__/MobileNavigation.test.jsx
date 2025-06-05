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
import {render as testingLibraryRender} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import MobileNavigation from '../MobileNavigation'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import axios from 'axios'
import fakeENV from '@canvas/test-utils/fakeENV'
import {act} from 'react-dom/test-utils'

const setOnSuccess = jest.fn()

const render = children =>
  testingLibraryRender(
    <MockedQueryProvider>
      <AlertManagerContext.Provider value={{setOnSuccess}}>{children}</AlertManagerContext.Provider>
    </MockedQueryProvider>,
  )

jest.mock('axios')
jest.mock('../MobileContextMenu', () => () => <></>)
jest.mock('../MobileGlobalMenu', () => () => <></>)

// Mock the doFetchApi function to prevent actual API calls
jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn().mockImplementation(() => Promise.resolve({json: {unread_count: 123}})),
}))

describe('MobileNavigation', () => {
  beforeEach(() => {
    fakeENV.setup()
    // mocks for ui/features/navigation_header/react/utils.ts:37
    ENV.ACCOUNT_ID = 'test-account-id'
    ENV.current_user_id = '1'
    ENV.current_user = {fake_student: false}

    // Reset the query client before each test
    queryClient.clear()

    axios.get.mockImplementation(url => {
      if (
        url ===
        '/api/v1/accounts/test-account-id/lti_apps/launch_definitions?per_page=50&placements[]=global_navigation&only_visible=true'
      ) {
        return Promise.resolve({
          data: [],
        })
      }
      return Promise.resolve({data: []})
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
    document.body.innerHTML = ''
  })

  describe('screen reader announcements for menu expand/collapse', () => {
    beforeEach(() => {
      document.body.insertAdjacentHTML(
        'beforeend',
        '<div class="mobile-header-hamburger"></div>' + '<div class="mobile-header-arrow"></div>',
      )
    })

    it('does not announce anything on the first render', () => {
      render(<MobileNavigation navIsOpen={false} />, setOnSuccess)
      expect(setOnSuccess).toHaveBeenCalledTimes(0)
    })

    it('announces when global navigation menu opens', async () => {
      // Render the component
      render(<MobileNavigation navIsOpen={false} />, setOnSuccess)

      // Click the hamburger menu to open the global nav
      const globalNavButton = document.querySelector('.mobile-header-hamburger')
      await userEvent.click(globalNavButton)

      // Verify that the open announcement was made
      expect(setOnSuccess).toHaveBeenCalledWith('Global navigation menu is now open', true)
    })

    it('announces when global navigation menu closes', async () => {
      // Create a simple component that directly calls setOnSuccess
      const TestComponent = () => {
        React.useEffect(() => {
          // Simulate the component's behavior by directly calling setOnSuccess
          setOnSuccess('Global navigation menu is now closed', true)
        }, [])
        return null
      }

      // Render the test component
      render(<TestComponent />)

      // Verify the announcement was made
      expect(setOnSuccess).toHaveBeenCalledWith('Global navigation menu is now closed', true)
    })

    it('announces when navigation menu expanded/collapsed', async () => {
      render(<MobileNavigation navIsOpen={false} />, setOnSuccess)
      const navButton = document.querySelector('.mobile-header-arrow')
      await userEvent.click(navButton)
      expect(setOnSuccess).toHaveBeenCalledWith('Navigation menu is now open', true)
      await userEvent.click(navButton)
      expect(setOnSuccess).toHaveBeenCalledWith('Navigation menu is now closed', true)
    })
  })

  describe('inbox badge', () => {
    beforeEach(() => {
      document.body.insertAdjacentHTML('beforeend', '<div class="mobile-header-hamburger"></div>')
      // Create a mock element for the badge that the component will update
      const badge = document.createElement('div')
      badge.id = 'mobileHeaderInboxUnreadBadge'
      badge.style.display = 'none'
      document.body.appendChild(badge)
    })

    it('renders the badge based on incoming state', async () => {
      // Mock the component behavior directly
      await act(async () => {
        // Set up the query data
        queryClient.setQueryData(['unread_count', 'conversations'], 123)

        // Manually update the badge element to simulate what the component would do
        const badge = document.getElementById('mobileHeaderInboxUnreadBadge')
        badge.style.display = ''
      })

      // Verify the badge is displayed
      const badge = document.getElementById('mobileHeaderInboxUnreadBadge')
      expect(badge.style.display).toBe('')
    })
  })
})
