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
import {windowPathname} from '@canvas/util/globalUtils'
import {within} from '@testing-library/dom'
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLogin, useNewLoginData} from '../../context'
import {performSignIn} from '../../services'
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
      loginHandleName: 'Email',
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
  windowPathname: jest.fn(),
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
    ;(windowPathname as jest.Mock).mockReturnValue('')
  })

  beforeEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
    // reset the mock implementation to return the default values
    ;(useNewLoginData as jest.Mock).mockImplementation(() => ({
      loginHandleName: 'Email',
    }))
    ;(useNewLogin as jest.Mock).mockReturnValue({
      isUiActionPending: false,
      setIsUiActionPending: jest.fn(),
      otpRequired: false,
      setOtpRequired: jest.fn(),
      rememberMe: false,
      setRememberMe: jest.fn(),
      loginFailed: true,
      setLoginFailed: jest.fn(),
    })
  })

  afterEach(() => {
    cleanup()
  })

  describe('error handling', () => {
    it('displays a flash error with an error message when a network or unexpected API error occurs', async () => {
      ;(performSignIn as jest.Mock).mockRejectedValueOnce(new Error('Network error'))
      setup()
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

    it('shows username error state and clears password when login fails due to invalid credentials', async () => {
      // mock login request to simulate 400 Invalid Credentials error
      ;(performSignIn as jest.Mock).mockRejectedValueOnce({response: {status: 400}})
      // initial context state before login attempt
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
      // simulate typing credentials and submitting the form
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'wrongpassword')
      await userEvent.click(loginButton)
      // ensure performSignIn was called with the expected values
      await waitFor(() => {
        expect(performSignIn).toHaveBeenCalledWith(
          'user@example.com',
          'wrongpassword',
          false,
          '/login/canvas',
        )
      })
      // update context to simulate re-render with loginFailed=true
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        setRememberMe: jest.fn(),
        loginFailed: true,
        setLoginFailed: jest.fn(),
      })
      // check form-field validation error states
      const usernameError = await screen.findByText(
        'Please verify your email and password and try again.',
      )
      expect(usernameError).toBeInTheDocument()
      expect(usernameInput).toHaveAttribute('aria-invalid', 'true')
      expect(passwordInput).not.toHaveAttribute('aria-invalid')
    })
  })

  describe('remember me functionality', () => {
    it('renders the "Remember Me" checkbox correctly', () => {
      setup()
      const rememberMeCheckbox = screen.getByTestId('remember-me-checkbox')
      expect(rememberMeCheckbox).toBeInTheDocument()
      expect(rememberMeCheckbox).not.toBeChecked()
    })

    it('passes the correct "Remember Me" value when checked', async () => {
      ;(windowPathname as jest.Mock).mockReturnValue('/login/canvas')

      // Mock the useNewLogin hook to return rememberMe: true when checkbox is clicked
      const setRememberMeMock = jest.fn()
      ;(useNewLogin as jest.Mock)
        .mockReturnValueOnce({
          isUiActionPending: false,
          setIsUiActionPending: jest.fn(),
          otpRequired: false,
          setOtpRequired: jest.fn(),
          rememberMe: false,
          setRememberMe: setRememberMeMock,
          loginFailed: false,
          setLoginFailed: jest.fn(),
        })
        .mockReturnValue({
          isUiActionPending: false,
          setIsUiActionPending: jest.fn(),
          otpRequired: false,
          setOtpRequired: jest.fn(),
          rememberMe: true,
          setRememberMe: setRememberMeMock,
          loginFailed: false,
          setLoginFailed: jest.fn(),
        })

      setup()
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const rememberMeCheckbox = screen.getByTestId('remember-me-checkbox')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(rememberMeCheckbox)
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).toHaveBeenCalledWith(
          'user@example.com',
          'password123',
          true,
          '/login/canvas',
        )
      })
    })

    it('passes the correct "Remember Me" value when unchecked', async () => {
      ;(windowPathname as jest.Mock).mockReturnValue('/login/canvas')
      setup()
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).toHaveBeenCalledWith(
          'user@example.com',
          'password123',
          false,
          '/login/canvas',
        )
      })
    })
  })
})
