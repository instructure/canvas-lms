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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLogin, useNewLoginData} from '../../context'
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
    useNewLogin: jest.fn(() => ({
      isUiActionPending: false,
      setIsUiActionPending: jest.fn(),
      otpRequired: false,
      setOtpRequired: jest.fn(),
      rememberMe: false,
      setRememberMe: jest.fn(),
      loginFailed: false,
      setLoginFailed: jest.fn(),
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
  windowPathname: jest.fn().mockReturnValue('/login/canvas'),
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
  })

  afterEach(() => {
    cleanup()
  })

  describe('form validation', () => {
    it('shows validation error when the username contains only whitespace', async () => {
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        setRememberMe: jest.fn(),
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })
      setup()
      const usernameInput = screen.getByTestId('username-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, '   ')
      await userEvent.click(loginButton)
      const usernameError = await screen.findByText('Please enter your email.')
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
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        setRememberMe: jest.fn(),
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })
      setup()
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
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        setRememberMe: jest.fn(),
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })
      setup()
      const usernameInput = screen.getByTestId('username-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, '   ')
      await userEvent.click(loginButton)
      expect(usernameInput).toHaveAttribute('aria-invalid', 'true')
      await userEvent.clear(usernameInput)
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      const passwordInput = screen.getByTestId('password-input')
      expect(passwordInput).toHaveAttribute('aria-invalid', 'true')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      expect(passwordInput).not.toHaveAttribute('aria-invalid')
    })

    it('marks both username and password fields as valid after sequential validation with correct input', async () => {
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        setRememberMe: jest.fn(),
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })
      setup()
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
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        setRememberMe: jest.fn(),
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })
      setup()
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
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        setRememberMe: jest.fn(),
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })
      setup()
      const loginButton = screen.getByTestId('login-button')
      await userEvent.click(loginButton)
      const emailError = await screen.findByText('Please enter your email.')
      expect(emailError).toBeInTheDocument()
      const usernameInput = screen.getByTestId('username-input')
      await userEvent.type(usernameInput, 'test@example.com')
      await userEvent.click(loginButton)
      const passwordError = await screen.findByText('Please enter your password.')
      expect(passwordError).toBeInTheDocument()
    })

    it('validates all fields at once on form submission', async () => {
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        setRememberMe: jest.fn(),
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })
      setup()
      const loginButton = screen.getByTestId('login-button')
      await userEvent.click(loginButton)
      expect(await screen.findByText('Please enter your email.')).toBeInTheDocument()
      expect(await screen.findByText('Please enter your password.')).toBeInTheDocument()
      const emailInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      await userEvent.type(emailInput, 'user@example.com')
      await userEvent.click(loginButton)
      expect(screen.queryByText('Please enter your email.')).not.toBeInTheDocument()
      expect(await screen.findByText('Please enter your password.')).toBeInTheDocument()
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(screen.queryByText('Please enter your email.')).not.toBeInTheDocument()
        expect(screen.queryByText('Please enter your password.')).not.toBeInTheDocument()
      })
    })

    // fickle
    describe.skip('otp flow', () => {
      it('redirects to the OtpForm component and removes the username and password inputs when OTP is required', async () => {
        const setOtpRequired = jest.fn()
        ;(useNewLogin as jest.Mock).mockReturnValue({
          isUiActionPending: false,
          setIsUiActionPending: jest.fn(),
          otpRequired: false,
          setOtpRequired,
          rememberMe: false,
          setRememberMe: jest.fn(),
          loginFailed: false,
          setLoginFailed: jest.fn(),
        })
        ;(performSignIn as jest.Mock).mockResolvedValue({
          status: 200,
          data: {otp_required: true},
        })
        ;(initiateOtpRequest as jest.Mock).mockResolvedValue({
          status: 200,
          data: {otp_sent: true, otp_communication_channel_id: '12345'},
        })
        setup()
        const usernameInput = screen.getByTestId('username-input')
        const passwordInput = screen.getByTestId('password-input')
        const loginButton = screen.getByTestId('login-button')
        await userEvent.type(usernameInput, 'user@example.com')
        await userEvent.type(passwordInput, 'password123')
        await userEvent.click(loginButton)
        await waitFor(() => {
          expect(performSignIn).toHaveBeenCalledWith('user@example.com', 'password123', false)
        })
        ;(useNewLogin as jest.Mock).mockReturnValue({
          isUiActionPending: false,
          setIsUiActionPending: jest.fn(),
          otpRequired: true,
          setOtpRequired,
          rememberMe: false,
          setRememberMe: jest.fn(),
          loginFailed: false,
          setLoginFailed: jest.fn(),
        })
        await waitFor(() => {
          expect(screen.getByText(/Multi-Factor Authentication/i)).toBeInTheDocument()
        })
        expect(screen.queryByTestId('username-input')).not.toBeInTheDocument()
        expect(screen.queryByTestId('password-input')).not.toBeInTheDocument()
      })
    })
  })
})
