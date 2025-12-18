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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import LoginHelp from '../loginHelp'

const server = setupServer(
  http.get('*', () => {
    return HttpResponse.json([{}])
  }),
)

describe('LoginHelp Component', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
    document.body.innerHTML = ''
  })

  afterEach(async () => {
    cleanup()
    document.body.innerHTML = ''
    // Allow any pending timers to settle
    await waitFor(() => {}, {timeout: 100}).catch(() => {})
  })

  it('renders the link text correctly', () => {
    render(
      <MockedQueryProvider>
        <LoginHelp linkText="Help" />
      </MockedQueryProvider>,
    )
    expect(screen.getByText('Help')).toBeInTheDocument()
  })

  it('shows modal initially with close button', async () => {
    const {getByRole, getByTestId, getByText} = render(
      <MockedQueryProvider>
        <LoginHelp linkText="Help" />
      </MockedQueryProvider>,
    )

    // Modal should be open initially
    expect(getByRole('dialog', {name: 'Login Help for Canvas LMS'})).toBeInTheDocument()
    expect(getByText('Help')).toBeInTheDocument()

    // Verify close button exists
    expect(getByTestId('login-help-close-button')).toBeInTheDocument()
  })

  it('handles close button click', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(
      <MockedQueryProvider>
        <LoginHelp linkText="Help" />
      </MockedQueryProvider>,
    )

    // Close button should be clickable
    const closeButton = getByTestId('login-help-close-button')
    await user.click(closeButton)

    // Wait for modal to start closing animation
    await waitFor(() => {}, {timeout: 150}).catch(() => {})
  })
})
