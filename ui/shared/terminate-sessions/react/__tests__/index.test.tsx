/*
 * Copyright (C) 2026 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import TerminateSessions from '../index'

vi.mock('@instructure/platform-alerts', async () => {
  const actual = await vi.importActual('@instructure/platform-alerts')
  return {
    ...actual,
    showFlashSuccess: vi.fn(() => vi.fn()),
    showFlashError: vi.fn(() => vi.fn()),
  }
})

import {showFlashSuccess, showFlashError} from '@instructure/platform-alerts'

const server = setupServer()

beforeAll(() => server.listen())
afterEach(() => {
  server.resetHandlers()
  vi.clearAllMocks()
})
afterAll(() => server.close())

const BUTTON_TEXT = 'Terminate all sessions for this user'
const user = {id: '123', name: 'John Doe'}

describe('TerminateSessions', () => {
  const renderModal = async () => {
    render(<TerminateSessions user={user} />)

    await userEvent.click(screen.getByRole('button', {name: BUTTON_TEXT}))
  }

  it('renders the name of the user in the confirmation message', async () => {
    await renderModal()

    expect(screen.getByText(/This will terminate all user sessions for /)).toBeInTheDocument()
    expect(screen.getByText(user.name)).toBeInTheDocument()
  })

  it('opens confirmation modal on button click', async () => {
    await renderModal()

    expect(screen.getByText(/This will terminate all user sessions for /)).toBeInTheDocument()
    expect(screen.getByText(/The user can immediately re-authenticate/)).toBeInTheDocument()
  })

  it('closes modal via footer Close button', async () => {
    await renderModal()

    const closeButtons = screen.getAllByRole('button', {name: 'Close'})
    // Footer Close button is the last one (header X button comes first)
    await userEvent.click(closeButtons[closeButtons.length - 1])

    await waitFor(() => {
      expect(
        screen.queryByText(/This will terminate all user sessions for /),
      ).not.toBeInTheDocument()
    })
  })

  it('closes modal via header X button', async () => {
    await renderModal()

    const closeButtons = screen.getAllByRole('button', {name: 'Close'})
    await userEvent.click(closeButtons[0])

    await waitFor(() => {
      expect(
        screen.queryByText(/This will terminate all user sessions for /),
      ).not.toBeInTheDocument()
    })
  })

  it('terminates sessions successfully', async () => {
    let requestReceived = false
    server.use(
      http.delete('/api/v1/users/123/sessions', () => {
        requestReceived = true
        return HttpResponse.json({}, {status: 200})
      }),
    )
    await renderModal()

    await userEvent.click(screen.getByRole('button', {name: 'Confirm'}))

    await waitFor(() => {
      expect(requestReceived).toBe(true)
    })
    expect(showFlashSuccess).toHaveBeenCalledWith('All sessions have been terminated successfully.')
    await waitFor(() => {
      expect(
        screen.queryByText(/This will terminate all user sessions for /),
      ).not.toBeInTheDocument()
    })
  })

  it('shows error flash on failed session termination', async () => {
    server.use(
      http.delete('/api/v1/users/:userId/sessions', () => {
        return HttpResponse.json({error: 'Internal Server Error'}, {status: 500})
      }),
    )
    await renderModal()

    await userEvent.click(screen.getByRole('button', {name: 'Confirm'}))

    await waitFor(() => {
      expect(showFlashError).toHaveBeenCalledWith(
        'An error occurred while terminating sessions. Please try again.',
      )
    })
    await waitFor(() => {
      expect(
        screen.queryByText(/This will terminate all user sessions for /),
      ).not.toBeInTheDocument()
    })
  })
})
