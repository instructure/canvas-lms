/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {HorizonAccount} from '../HorizonAccount'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const server = setupServer()

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

vi.mock('@canvas/alerts/react/FlashAlert', async () => ({
  ...await vi.importActual('@canvas/alerts/react/FlashAlert'),
  showFlashError: vi.fn(),
}))

describe('HorizonAccount', () => {
  const setup = (propOverrides = {}) => {
    const props = {
      accountId: '123',
      hasCourses: false,
      locked: false,
      ...propOverrides,
    }
    return render(<HorizonAccount {...props} />)
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

  it('renders the component', () => {
    setup()
    expect(screen.getByText('Changes to Courses & Content')).toBeInTheDocument()
  })

  it('button and checkbox are enabled', () => {
    setup()
    const button = screen.getByText('Switch to Canvas Career')
    const checkbox = screen.getByLabelText(/I acknowledge that switching to Canvas Career/)
    expect(button).not.toBeDisabled()
    expect(checkbox).not.toBeDisabled()
  })

  it('disables the checkbox when account has courses', () => {
    setup({hasCourses: true})
    const checkbox = screen.getByLabelText(/I acknowledge that switching to Canvas Career/)
    expect(checkbox).toBeDisabled()
  })

  it('disables the checkbox when account is locked', () => {
    setup({locked: true})
    const checkbox = screen.getByLabelText(/I acknowledge that switching to Canvas Career/)
    expect(checkbox).toBeDisabled()
  })

  it('makes an API call when the button is clicked', async () => {
    let capturedBody: any = null
    server.use(
      http.put('/api/v1/accounts/123', async ({request}) => {
        capturedBody = await request.json()
        return HttpResponse.json({})
      }),
    )

    setup()
    const checkbox = screen.getByLabelText(/I acknowledge that switching to Canvas Career/)
    fireEvent.click(checkbox)
    const button = screen.getByText('Switch to Canvas Career')
    fireEvent.click(button)

    await waitFor(() => {
      expect(capturedBody).toEqual({
        id: '123',
        account: {settings: {horizon_account: {value: true}}},
      })
    })
  })

  it('shows an error message when API call fails', async () => {
    server.use(http.put('/api/v1/accounts/123', () => HttpResponse.error()))

    setup()
    const checkbox = screen.getByLabelText(/I acknowledge that switching to Canvas Career/)
    fireEvent.click(checkbox)
    const button = screen.getByText('Switch to Canvas Career')
    fireEvent.click(button)

    await waitFor(() => {
      expect(showFlashError).toHaveBeenCalledWith(
        'Failed to switch to Canvas Career. Please try again.',
      )
    })
  })
})
