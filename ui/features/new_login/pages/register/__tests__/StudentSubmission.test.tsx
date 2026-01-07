/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {assignLocation} from '@canvas/util/globalUtils'
import {cleanup, render, screen, waitFor, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import {MemoryRouter} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLoginData} from '../../../context'
import {createStudentAccount} from '../../../services'
import Student from '../Student'

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

vi.mock('../../../services', () => ({
  createStudentAccount: vi.fn(),
}))

vi.mock('../../../context', async () => {
  const actual = await vi.importActual<typeof import('../../../context')>('../../../context')
  return {
    ...actual,
    useNewLoginData: vi.fn(() => ({
      isDataLoading: false,
    })),
  }
})

describe('Student - form submission', () => {
  let user: ReturnType<typeof userEvent.setup>

  const setup = () => {
    user = userEvent.setup()
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <Student />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
  }

  beforeEach(() => {
    vi.clearAllMocks()
    vi.restoreAllMocks()
    ;(useNewLoginData as ReturnType<typeof vi.fn>).mockImplementation(() => ({
      isDataLoading: false,
      loginHandleName: 'Email',
      privacyPolicyUrl: '',
      requireEmail: false,
      termsOfUseUrl: '',
      termsRequired: false,
    }))
  })

  afterEach(() => {
    cleanup()
  })

  it('submits successfully with valid inputs', async () => {
    ;(createStudentAccount as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      status: 200,
      data: {success: true, destination: '/dashboard'},
    })
    setup()
    await user.type(screen.getByTestId('name-input'), 'Student User')
    await user.type(screen.getByTestId('username-input'), 'studentusername')
    await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('join-code-input'), 'JOIN123')
    await user.click(screen.getByTestId('submit-button'))
    await waitFor(() => {
      expect(createStudentAccount).toHaveBeenCalledWith({
        name: 'Student User',
        username: 'studentusername',
        password: 'ValidPassword123!',
        confirmPassword: 'ValidPassword123!',
        joinCode: 'JOIN123',
        captchaToken: undefined,
        email: undefined,
        termsAccepted: false,
      })
    })
  })

  it('shows error messages for failed API validation', async () => {
    ;(createStudentAccount as ReturnType<typeof vi.fn>).mockRejectedValueOnce({
      response: {
        json: async () => ({
          errors: {
            pseudonym: {
              unique_id: [{type: 'taken', message: 'taken'}],
            },
            user: {
              self_enrollment_code: [{type: 'invalid', message: 'invalid'}],
            },
          },
        }),
      },
    })
    setup()
    await user.type(screen.getByTestId('name-input'), 'Student User')
    await user.type(screen.getByTestId('username-input'), 'existingusername')
    await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('join-code-input'), 'INVALID')
    await user.click(screen.getByTestId('submit-button'))
    expect(await screen.findByText('This username is already in use.')).toBeInTheDocument()
    expect(screen.getByText('The enrollment code is invalid.')).toBeInTheDocument()
  })

  it('handles generic server errors gracefully', async () => {
    ;(createStudentAccount as ReturnType<typeof vi.fn>).mockRejectedValueOnce({
      response: {
        status: 500,
        json: async () => ({}),
      },
    })
    setup()
    await user.type(screen.getByTestId('name-input'), 'Student User')
    await user.type(screen.getByTestId('username-input'), 'studentusername')
    await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('join-code-input'), 'JOIN123')
    await user.click(screen.getByTestId('submit-button'))
    await waitFor(() => {
      const alertContainer = document.querySelector('.flashalert-message') as HTMLElement
      const flashAlert = within(alertContainer!).getByText(
        'Something went wrong. Please try again later.',
      )
      expect(flashAlert).toBeInTheDocument()
    })
  })

  it('redirects to the provided destination after a successful submission', async () => {
    ;(createStudentAccount as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      status: 200,
      data: {success: true, destination: '/custom-redirect'},
    })
    setup()
    await user.type(screen.getByTestId('name-input'), 'Student User')
    await user.type(screen.getByTestId('username-input'), 'studentusername')
    await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('join-code-input'), 'JOIN123')
    await user.click(screen.getByTestId('submit-button'))
    await waitFor(() => {
      expect(assignLocation).toHaveBeenCalledWith('/custom-redirect')
    })
  })

  it('redirects to the default location if no destination is provided', async () => {
    ;(createStudentAccount as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      status: 200,
      data: {success: true},
    })
    setup()
    await user.type(screen.getByTestId('name-input'), 'Student User')
    await user.type(screen.getByTestId('username-input'), 'studentusername')
    await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
    await user.type(screen.getByTestId('join-code-input'), 'JOIN123')
    await user.click(screen.getByTestId('submit-button'))
    await waitFor(() => {
      expect(assignLocation).toHaveBeenCalledWith('/?registration_success=1')
    })
  })

  it('navigates to login when the cancel button is clicked', async () => {
    setup()
    const backButton = screen.getByTestId('back-button')
    await user.click(backButton)
    await waitFor(() => {
      expect(assignLocation).toHaveBeenCalledWith('/login')
    })
  })
})
