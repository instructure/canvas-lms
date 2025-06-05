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
import {HorizonAccount} from '../HorizonAccount'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: jest.fn(),
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

  it('makes an API call when the button is clicked', () => {
    ;(doFetchApi as jest.Mock).mockResolvedValue({
      response: {status: 200},
    })
    setup()
    const checkbox = screen.getByLabelText(/I acknowledge that switching to Canvas Career/)
    fireEvent.click(checkbox)
    const button = screen.getByText('Switch to Canvas Career')
    fireEvent.click(button)
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/accounts/123',
      method: 'PUT',
      body: {
        id: '123',
        account: {settings: {horizon_account: {value: true}}},
      },
    })
  })

  it('shows an error message when API call fails', () => {
    ;(doFetchApi as jest.Mock).mockRejectedValue(new Error('Failed to switch to Canvas Career'))
    setup()
    const checkbox = screen.getByLabelText(/I acknowledge that switching to Canvas Career/)
    fireEvent.click(checkbox)
    const button = screen.getByText('Switch to Canvas Career')
    fireEvent.click(button)
    waitFor(() => {
      expect(screen.getByText('Failed to switch to Canvas Career')).toBeInTheDocument()
    })
  })
})
