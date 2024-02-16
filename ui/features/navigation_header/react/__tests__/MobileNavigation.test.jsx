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
import {QueryProvider, queryClient} from '@canvas/query'

const render = children => testingLibraryRender(<QueryProvider>{children}</QueryProvider>)

describe('MobileNavigation', () => {
  it('renders the inbox badge based on incoming state', async () => {
    queryClient.setQueryData(['unread_count', 'conversations'], 123)
    const hamburgerMenu = document.createElement('div')
    hamburgerMenu.setAttribute('class', 'mobile-header-hamburger')
    document.body.appendChild(hamburgerMenu)
    const {findByText, queryByText} = render(<MobileNavigation />)
    await userEvent.click(hamburgerMenu)
    await waitFor(() => {
      expect(queryByText('Loading ...')).not.toBeInTheDocument()
    })
    const count = await findByText('123')
    expect(count).toBeInTheDocument()
  })
})
