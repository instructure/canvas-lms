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

describe('Student', () => {
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
    // reset the mock implementation to return the default values
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

  describe('form rendering', () => {
    it('renders all required input fields', async () => {
      setup()
      expect(await screen.findByTestId('name-input')).toBeInTheDocument()
      expect(screen.getByTestId('username-input')).toBeInTheDocument()
      expect(screen.getByTestId('password-input')).toBeInTheDocument()
      expect(screen.getByTestId('confirm-password-input')).toBeInTheDocument()
      expect(screen.getByTestId('join-code-input')).toBeInTheDocument()
    })

    it('renders terms checkbox when required', async () => {
      ;(useNewLoginData as ReturnType<typeof vi.fn>).mockImplementation(() => ({
        isDataLoading: false,
        termsRequired: true,
        privacyPolicyUrl: 'http://www.example.com/privacy',
        termsOfUseUrl: 'http://www.example.com/terms',
      }))
      setup()
      expect(await screen.findByTestId('terms-and-policy-checkbox')).toBeInTheDocument()
    })

    it('renders email input when required', async () => {
      ;(useNewLoginData as ReturnType<typeof vi.fn>).mockImplementation(() => ({
        isDataLoading: false,
        requireEmail: true,
      }))
      setup()
      expect(await screen.findByTestId('email-input')).toBeInTheDocument()
    })
  })

  describe('form validation', () => {
    beforeEach(() => {
      ;(useNewLoginData as ReturnType<typeof vi.fn>).mockImplementation(() => ({
        isDataLoading: false,
        privacyPolicyUrl: 'http://www.example.com/privacy',
        requireEmail: true,
        termsOfUseUrl: 'http://www.example.com/terms',
        termsRequired: true,
      }))
    })

    it('shows an error for a missing name and focuses the name input', async () => {
      setup()
      await user.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Name is required.')).toBeInTheDocument()
      expect(document.activeElement).toBe(screen.getByTestId('name-input'))
      await user.type(screen.getByTestId('name-input'), 'John Doe')
      await user.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Name is required.')).not.toBeInTheDocument()
    })

    it('shows an error for a missing username and focuses the username input', async () => {
      setup()
      await user.type(screen.getByTestId('name-input'), 'John Doe')
      await user.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Username is required.')).toBeInTheDocument()
      expect(document.activeElement).toBe(screen.getByTestId('username-input'))
      await user.type(screen.getByTestId('username-input'), 'validusername')
      await user.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Username is required.')).not.toBeInTheDocument()
    })

    it('shows an error when the password is missing and focuses the password input', async () => {
      setup()
      await user.type(screen.getByTestId('name-input'), 'John Doe')
      await user.type(screen.getByTestId('username-input'), 'validusername')
      await user.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Password is required.')).toBeInTheDocument()
      expect(document.activeElement).toBe(screen.getByTestId('password-input'))
      await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await user.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Password is required.')).not.toBeInTheDocument()
    })

    it('validates that passwords match and focuses the confirm password input', async () => {
      setup()
      await user.type(screen.getByTestId('name-input'), 'John Doe')
      await user.type(screen.getByTestId('username-input'), 'validusername')
      await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await user.type(screen.getByTestId('confirm-password-input'), 'MismatchPassword')
      await user.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Passwords do not match.')).toBeInTheDocument()
      await waitFor(() => {
        expect(document.activeElement).toBe(screen.getByTestId('confirm-password-input'))
      })
      await user.clear(screen.getByTestId('confirm-password-input'))
      await user.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(screen.queryByText('Passwords do not match.')).not.toBeInTheDocument()
      })
    })

    it('validates the join code field and focuses the join code input', async () => {
      setup()
      await user.type(screen.getByTestId('name-input'), 'John Doe')
      await user.type(screen.getByTestId('username-input'), 'validusername')
      await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await user.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await user.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Join code is required.')).toBeInTheDocument()
      await waitFor(() => {
        expect(document.activeElement).toBe(screen.getByTestId('join-code-input'))
      })
      await user.type(screen.getByTestId('join-code-input'), 'JOIN123')
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(screen.queryByText('Join code is required.')).not.toBeInTheDocument()
      })
    })

    it('validates the email field when required and focuses the email input', async () => {
      setup()
      await user.type(screen.getByTestId('name-input'), 'John Doe')
      await user.type(screen.getByTestId('username-input'), 'validusername')
      await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await user.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await user.type(screen.getByTestId('join-code-input'), 'JOIN123')
      await user.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Please enter a valid email address.')).toBeInTheDocument()
      await waitFor(() => {
        expect(document.activeElement).toBe(screen.getByTestId('email-input'))
      })
      await user.type(screen.getByTestId('email-input'), 'valid@example.com')
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(screen.queryByText('Please enter a valid email address.')).not.toBeInTheDocument()
      })
    })

    it('validates the terms checkbox when required', async () => {
      setup()
      await user.type(screen.getByTestId('name-input'), 'John Doe')
      await user.type(screen.getByTestId('username-input'), 'validusername')
      await user.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await user.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await user.type(screen.getByTestId('join-code-input'), 'JOIN123')
      await user.type(screen.getByTestId('email-input'), 'valid@example.com')
      await user.click(screen.getByTestId('submit-button'))
      expect(
        await screen.findByText('You must accept the terms to create an account.'),
      ).toBeInTheDocument()
      await user.click(screen.getByTestId('terms-and-policy-checkbox'))
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(
          screen.queryByText('You must accept the terms to create an account.'),
        ).not.toBeInTheDocument()
      })
    })

    it('does not clear the name error until submit is clicked again', async () => {
      setup()
      await user.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Name is required.')).toBeInTheDocument()
      await user.type(screen.getByTestId('name-input'), 'John Doe')
      expect(screen.queryByText('Name is required.')).toBeInTheDocument()
      await user.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Name is required.')).not.toBeInTheDocument()
    })
  })

  describe('form submission', () => {
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
