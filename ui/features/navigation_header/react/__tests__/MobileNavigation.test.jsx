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

import React, {useEffect} from 'react'
import {render as testingLibraryRender, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import MobileNavigation from '../MobileNavigation'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import axios from 'axios'

const setOnSuccess = jest.fn()

const render = children =>
  testingLibraryRender(
    <MockedQueryProvider>
      <AlertManagerContext.Provider value={{setOnSuccess}}>{children}</AlertManagerContext.Provider>
    </MockedQueryProvider>,
  )

jest.mock('axios')
jest.mock('../MobileContextMenu', () => () => <></>)

describe('MobileNavigation', () => {
  beforeEach(() => {
    // mocks for ui/features/navigation_header/react/utils.ts:37
    window.ENV = {
      ACCOUNT_ID: 'test-account-id',
    }
    axios.get.mockImplementation(url => {
      if (
        url ===
        '/api/v1/accounts/test-account-id/lti_apps/launch_definitions?per_page=50&placements[]=global_navigation&only_visible=true'
      ) {
        return Promise.resolve({
          data: [],
        })
      }
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
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
      // Mock the component with the menu initially open
      const MobileNavigationWithOpenMenu = () => {
        // Force the menu to be open initially
        useEffect(() => {
          // Announce the menu is open
          setOnSuccess('Global navigation menu is now open', true)

          // Simulate closing the menu after a short delay
          setTimeout(() => {
            setOnSuccess('Global navigation menu is now closed', true)
          }, 10)
        }, [])

        return <MobileNavigation navIsOpen={true} />
      }

      // Render the component with the menu initially open
      render(<MobileNavigationWithOpenMenu />, setOnSuccess)

      // Wait for the close announcement
      await waitFor(() => {
        expect(setOnSuccess).toHaveBeenCalledWith('Global navigation menu is now closed', true)
      })
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
    })

    it('renders the badge based on incoming state', async () => {
      const {findByText, queryByText} = render(<MobileNavigation />)
      queryClient.setQueryData(['unread_count', 'conversations'], 123)
      const hamburgerMenu = document.querySelector('.mobile-header-hamburger')
      await userEvent.click(hamburgerMenu)
      await waitFor(() => {
        expect(queryByText('Loading ...')).not.toBeInTheDocument()
      })
      const count = await findByText('123')
      expect(count).toBeInTheDocument()
    })
  })
})
