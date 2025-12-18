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

import {cleanup, screen, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {renderLoginHelp} from '../loginHelp'

const server = setupServer(
  http.get('*', () => {
    return HttpResponse.json([{}])
  }),
)

describe('renderLoginHelp() - element validation', () => {
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

  it('renders help link when the provided element is an anchor element', async () => {
    const anchorElement = document.createElement('a')
    anchorElement.textContent = 'Help'
    document.body.appendChild(anchorElement)
    renderLoginHelp(anchorElement)
    expect(screen.getByText('Help')).toBeInTheDocument()
  })

  it('renders help link when the provided element is a direct child of an anchor element', async () => {
    const anchorElement = document.createElement('a')
    const spanElement = document.createElement('span')
    spanElement.textContent = 'Help'
    anchorElement.appendChild(spanElement)
    document.body.appendChild(anchorElement)
    renderLoginHelp(spanElement)
    expect(screen.getByText('Help')).toBeInTheDocument()
  })
})
