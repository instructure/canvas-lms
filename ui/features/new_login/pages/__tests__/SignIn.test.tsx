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

import React from 'react'
import '@testing-library/jest-dom'
import {assignLocation} from '@canvas/util/globalUtils'
import {within} from '@testing-library/dom'
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLoginData} from '../../context'
import {initiateOtpRequest, performSignIn} from '../../services'
import SignIn from '../SignIn'

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: jest.fn(),
}))

jest.mock('../../context', () => {
  const actualContext = jest.requireActual('../../context')
  return {
    ...actualContext,
    useNewLoginData: jest.fn(() => ({
      ...actualContext.useNewLoginData(),
    })),
  }
})

jest.mock('../../services/auth', () => ({
  performSignIn: jest.fn(),
  initiateOtpRequest: jest.fn(),
}))

jest.mock('@canvas/util/globalUtils', () => ({
  ...jest.requireActual('@canvas/util/globalUtils'),
  assignLocation: jest.fn(),
}))

describe('SignIn', () => {
  const setup = () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <SignIn />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
  }

  const mockNavigate = jest.fn()
  beforeAll(() => {
    ;(useNavigate as jest.Mock).mockReturnValue(mockNavigate)
  })

  beforeEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
    // reset the mock implementation to return the default values
    ;(useNewLoginData as jest.Mock).mockImplementation(() => ({
      loginHandleName: 'Email',
    }))
    setup()
  })

  afterEach(() => {
    cleanup()
  })

  describe('login behavior', () => {
    it('calls performSignIn with the correct parameters when valid credentials are submitted', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).toHaveBeenCalledWith('user@example.com', 'password123', false)
        expect(performSignIn).toHaveBeenCalledTimes(1)
      })
    })

    it('displays a login error alert when invalid credentials are submitted', async () => {
      ;(performSignIn as jest.Mock).mockRejectedValueOnce({response: {status: 400}})
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      await userEvent.type(passwordInput, 'wrongpassword')
      await userEvent.click(loginButton)
      await waitFor(() => {
        const loginError = screen.getByText('Please verify your email or password and try again.')
        expect(loginError).toBeInTheDocument()
      })
    })

    it('does not call performSignIn when the username is missing', async () => {
      const loginButton = screen.getByTestId('login-button')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).not.toHaveBeenCalled()
      })
    })

    it('does not call performSignIn when the password is missing', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).not.toHaveBeenCalled()
      })
    })
  })

  describe('ui State', () => {
    it('disables the "Log In" button when isUiActionPending is true', async () => {
      ;(performSignIn as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {pseudonym: true},
      })
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      expect(loginButton).toBeDisabled()
    })

    it('disables the username and password inputs during login submission', async () => {
      ;(performSignIn as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {pseudonym: true},
      })
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      expect(usernameInput).toBeDisabled()
      expect(passwordInput).toBeDisabled()
    })

    it('removes the error alert when the user starts typing in the username field', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.click(loginButton)
      const usernameError = await screen.findByText('Please enter your email')
      expect(usernameError).toBeInTheDocument()
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      expect(screen.queryByText('Please enter your email')).not.toBeInTheDocument()
    })

    it('removes the error alert when the user starts typing in the password field', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      const passwordError = await screen.findByText('Please enter your password.')
      expect(passwordError).toBeInTheDocument()
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      expect(screen.queryByText('Please enter your password.')).not.toBeInTheDocument()
    })
  })

  describe('error handling', () => {
    it('displays a flash error with an error message when a network or unexpected API error occurs', async () => {
      ;(performSignIn as jest.Mock).mockRejectedValueOnce(new Error('Network error'))
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        const alertContainer = document.querySelector('.flashalert-message') as HTMLElement
        const flashAlert = within(alertContainer!).getByText(
          'Something went wrong. Please try again later.',
        )
        expect(flashAlert).toBeInTheDocument()
      })
    })

    it('renders the LoginAlert component when login fails due to invalid credentials', async () => {
      ;(performSignIn as jest.Mock).mockRejectedValueOnce({response: {status: 400}})
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'wrongpassword')
      await userEvent.click(loginButton)
      await waitFor(() => {
        const loginAlert = screen.getByText('Please verify your email or password and try again.')
        expect(loginAlert).toBeInTheDocument()
      })
    })
  })

  describe('remember me functionality', () => {
    it('renders the "Remember Me" checkbox correctly', () => {
      const rememberMeCheckbox = screen.getByTestId('remember-me-checkbox')
      expect(rememberMeCheckbox).toBeInTheDocument()
      expect(rememberMeCheckbox).not.toBeChecked()
    })

    it('passes the correct "Remember Me" value to performSignIn when checked', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const rememberMeCheckbox = screen.getByTestId('remember-me-checkbox')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(rememberMeCheckbox)
      expect(rememberMeCheckbox).toBeChecked()
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).toHaveBeenCalledWith('user@example.com', 'password123', true)
      })
    })

    it('passes the correct "Remember Me" value to performSignIn when unchecked', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).toHaveBeenCalledWith('user@example.com', 'password123', false)
      })
    })
  })

  describe('redirects', () => {
    it('calls assignLocation with the correct URL after successful login', async () => {
      ;(performSignIn as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {pseudonym: true, location: '/dashboard'},
      })
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(assignLocation).toHaveBeenCalledWith('/dashboard')
        expect(assignLocation).toHaveBeenCalledTimes(1)
      })
    })

    it('calls assignLocation with /dashboard if no location is provided', async () => {
      ;(performSignIn as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {pseudonym: true},
      })
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(assignLocation).toHaveBeenCalledWith('/dashboard')
        expect(assignLocation).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe('user input', () => {
    it('trims whitespace from the username field when typing', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, '   user@example.com   ')
      await userEvent.click(loginButton)
      expect(usernameInput).toHaveValue('user@example.com')
      expect(usernameInput).not.toHaveValue('   user@example.com   ')
    })

    it('trims whitespace from the password field when typing', async () => {
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(passwordInput, '   password123   ')
      await userEvent.click(loginButton)
      expect(passwordInput).toHaveValue('password123')
      expect(passwordInput).not.toHaveValue('   password123   ')
    })
  })

  describe('form validation', () => {
    it('shows validation error when the username contains only whitespace', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, '   ')
      await userEvent.click(loginButton)
      const usernameError = await screen.findByText('Please enter your email')
      expect(usernameError).toBeInTheDocument()
      expect(usernameInput).toHaveAttribute('aria-invalid', 'true')
      const passwordError = screen.queryByText('Please enter your password.')
      expect(passwordError).toBeInTheDocument()
      await userEvent.clear(usernameInput)
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      expect(usernameInput).not.toHaveAttribute('aria-invalid')
      expect(passwordError).toBeInTheDocument()
    })

    it('shows validation error when the password contains only whitespace after fixing the username', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      expect(usernameInput).not.toHaveAttribute('aria-invalid')
      await userEvent.type(passwordInput, '   ')
      await userEvent.click(loginButton)
      const passwordError = await screen.findByText('Please enter your password.')
      expect(passwordError).toBeInTheDocument()
      expect(passwordInput).toHaveAttribute('aria-invalid', 'true')
      await userEvent.clear(passwordInput)
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      expect(passwordInput).not.toHaveAttribute('aria-invalid')
    })

    it('toggles the aria-invalid attribute correctly for both fields during sequential validation', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.click(loginButton)
      expect(usernameInput).toHaveAttribute('aria-invalid', 'true')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      expect(usernameInput).not.toHaveAttribute('aria-invalid')
      expect(passwordInput).toHaveAttribute('aria-invalid', 'true')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      expect(passwordInput).not.toHaveAttribute('aria-invalid')
    })

    it('marks both username and password fields as valid after sequential validation with correct input', async () => {
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      expect(usernameInput).not.toHaveAttribute('aria-invalid')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(passwordInput).not.toHaveAttribute('aria-invalid')
      })
    })

    it('does not submit if required fields are empty', async () => {
      const loginButton = screen.getByTestId('login-button')
      await userEvent.click(loginButton)
      const usernameInput = await screen.findByTestId('username-input')
      expect(usernameInput).toHaveAttribute('aria-invalid', 'true')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      const passwordInput = await screen.findByTestId('password-input')
      expect(passwordInput).toHaveAttribute('aria-invalid', 'true')
    })

    it('shows validation messages when fields are left blank', async () => {
      const loginButton = screen.getByTestId('login-button')
      await userEvent.click(loginButton)
      const emailError = await screen.findByText('Please enter your email')
      expect(emailError).toBeInTheDocument()
      const usernameInput = screen.getByTestId('username-input')
      await userEvent.type(usernameInput, 'test@example.com')
      await userEvent.click(loginButton)
      const passwordError = await screen.findByText('Please enter your password.')
      expect(passwordError).toBeInTheDocument()
    })

    it('validates all fields at once on form submission', async () => {
      const loginButton = screen.getByTestId('login-button')
      await userEvent.click(loginButton)
      expect(await screen.findByText('Please enter your email')).toBeInTheDocument()
      expect(await screen.findByText('Please enter your password.')).toBeInTheDocument()
      const emailInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      await userEvent.type(emailInput, 'user@example.com')
      await userEvent.click(loginButton)
      expect(screen.queryByText('Please enter your email')).not.toBeInTheDocument()
      expect(await screen.findByText('Please enter your password.')).toBeInTheDocument()
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(screen.queryByText('Please enter your email')).not.toBeInTheDocument()
        expect(screen.queryByText('Please enter your password.')).not.toBeInTheDocument()
      })
    })

    describe('otp flow', () => {
      beforeEach(() => {
        ;(performSignIn as jest.Mock).mockResolvedValue({
          status: 200,
          data: {otp_required: true},
        })
        ;(initiateOtpRequest as jest.Mock).mockResolvedValue({
          status: 200,
          data: {otp_sent: true, otp_communication_channel_id: '12345'},
        })
      })

      it('redirects to the OtpForm component and removes the username and password inputs when OTP is required', async () => {
        const usernameInput = screen.getByTestId('username-input')
        const passwordInput = screen.getByTestId('password-input')
        const loginButton = screen.getByTestId('login-button')
        await userEvent.type(usernameInput, 'user@example.com')
        await userEvent.type(passwordInput, 'password123')
        await userEvent.click(loginButton)
        await waitFor(() => {
          expect(screen.getByText(/Multi-Factor Authentication/i)).toBeInTheDocument()
        })
        expect(screen.queryByTestId('username-input')).not.toBeInTheDocument()
        expect(screen.queryByTestId('password-input')).not.toBeInTheDocument()
      })
    })
  })
})
