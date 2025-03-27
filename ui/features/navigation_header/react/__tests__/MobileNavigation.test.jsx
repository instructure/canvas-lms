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
import {render as testingLibraryRender, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import MobileNavigation from '../MobileNavigation'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import axios from 'axios'
import $ from "jquery";

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

// This is needed for $.screenReaderFlashMessageExclusive to work.
import '@canvas/rails-flash-notifications'

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
        '<div id="flash_screenreader_holder"></div>' +
          '<div class="mobile-header-hamburger"></div>' +
          '<div class="mobile-header-arrow"></div>',
      )
    })

    it('does not update the live region on the first render', () => {
      const flashMock = jest.spyOn($, 'screenReaderFlashMessageExclusive')
      render(<MobileNavigation navIsOpen={false} />)
      expect(flashMock).toHaveBeenCalledTimes(0)
    })

    it('announces when global navigation menu expanded/collapsed', async () => {
      const flashMock = jest.spyOn($, 'screenReaderFlashMessageExclusive')
      render(<MobileNavigation navIsOpen={false} />)
      const globalNavButton = document.querySelector('.mobile-header-hamburger')
      await userEvent.click(globalNavButton)
      expect(flashMock).toHaveBeenCalledWith('Global navigation menu is now open')
      await userEvent.click(globalNavButton)
      expect(flashMock).toHaveBeenCalledWith('Global navigation menu is now closed')
    })

    it('announces when context navigation menu expanded/collapsed', async () => {
      const flashMock = jest.spyOn($, 'screenReaderFlashMessageExclusive')
      render(<MobileNavigation navIsOpen={false} />)
      const contextNavButton = document.querySelector('.mobile-header-arrow')
      await userEvent.click(contextNavButton)
      expect(flashMock).toHaveBeenCalledWith('Course menu is now open')
      await userEvent.click(contextNavButton)
      expect(flashMock).toHaveBeenCalledWith('Course menu is now closed')
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
