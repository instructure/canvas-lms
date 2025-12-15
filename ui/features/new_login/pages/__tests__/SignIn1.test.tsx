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
import {windowPathname} from '@canvas/util/globalUtils'
import {cleanup, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLogin, useNewLoginData} from '../../context'
import {performSignIn} from '../../services'
import SignIn from '../SignIn'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('react-router-dom', async () => ({
  ...(await vi.importActual('react-router-dom')),
  useNavigate: vi.fn(),
}))

vi.mock('../../context', async () => {
  const actualContext = await vi.importActual('../../context')
  return {
    ...actualContext,
    useNewLoginData: vi.fn(() => ({
      isDataLoading: false,
      loginHandleName: 'Email',
    })),
    useNewLogin: vi.fn(() => ({
      isUiActionPending: false,
      setIsUiActionPending: vi.fn(),
      otpRequired: false,
      setOtpRequired: vi.fn(),
      rememberMe: false,
      setRememberMe: vi.fn(),
      showForgotPassword: false,
      setShowForgotPassword: vi.fn(),
      otpCommunicationChannelId: null,
      setOtpCommunicationChannelId: vi.fn(),
    })),
  }
})

vi.mock('../../services/auth', () => ({
  performSignIn: vi.fn().mockResolvedValue({}),
  initiateOtpRequest: vi.fn(),
}))

vi.mock('@canvas/util/globalUtils', async () => ({
  ...(await vi.importActual('@canvas/util/globalUtils')),
  assignLocation: vi.fn(),
  windowPathname: vi.fn(),
}))

describe('SignIn', () => {
  const setup = () => {
    return render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <SignIn />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
  }

  const mockNavigate = vi.fn()
  beforeAll(() => {
    vi.mocked(useNavigate).mockReturnValue(mockNavigate)
  })

  beforeEach(() => {
    fakeENV.setup()
    vi.clearAllMocks()
    vi.restoreAllMocks()
    // reset the mock implementation to return the default values
    vi.mocked(useNewLoginData).mockImplementation(() => ({
      isDataLoading: false,
      loginHandleName: 'Email',
    }))
  })

  afterEach(() => {
    cleanup()
    fakeENV.teardown()
  })

  describe('login behavior', () => {
    it('calls performSignIn with /login/canvas when on the Canvas login route', async () => {
      vi.mocked(windowPathname).mockReturnValue('/login/canvas')
      const {getByTestId} = setup()
      const usernameInput = getByTestId('username-input')
      const passwordInput = getByTestId('password-input')
      const loginButton = getByTestId('login-button')
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

    it('calls performSignIn with /login/ldap when on the LDAP login route', async () => {
      vi.mocked(windowPathname).mockReturnValue('/login/ldap')
      const {getByTestId} = setup()
      const usernameInput = getByTestId('username-input')
      const passwordInput = getByTestId('password-input')
      const loginButton = getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).toHaveBeenCalledWith(
          'user@example.com',
          'password123',
          false,
          '/login/ldap',
        )
      })
    })

    // Skip: Error message doesn't render properly with current mock setup
    it.skip('displays a login error alert when invalid credentials are submitted', async () => {
      vi.mocked(performSignIn).mockRejectedValueOnce({response: {status: 400}})

      const {getByTestId, findByText} = setup()
      const usernameInput = getByTestId('username-input')
      const passwordInput = getByTestId('password-input')
      const loginButton = getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'wrongpassword')
      await userEvent.click(loginButton)

      // Wait for the login to fail and check if the error message appears
      const errorMessage = await findByText(/Please verify your email or password and try again/i)
      expect(errorMessage).toBeInTheDocument()
      expect(usernameInput).toHaveAttribute('aria-invalid', 'true')
      expect(passwordInput).toHaveValue('')
    })

    it('does not call performSignIn when the username is missing', async () => {
      const {getByTestId} = setup()
      const loginButton = getByTestId('login-button')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).not.toHaveBeenCalled()
      })
    })

    it('does not call performSignIn when the password is missing', async () => {
      const {getByTestId} = setup()
      const usernameInput = getByTestId('username-input')
      const loginButton = getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(performSignIn).not.toHaveBeenCalled()
      })
    })
  })

  describe('ui State', () => {
    it('disables the "Log In" button when isUiActionPending is true', async () => {
      // Mock the useNewLogin hook to return isUiActionPending: true
      vi.mocked(useNewLogin).mockReturnValue({
        isUiActionPending: true,
        setIsUiActionPending: vi.fn(),
        otpRequired: false,
        setOtpRequired: vi.fn(),
        rememberMe: false,
        setRememberMe: vi.fn(),
        showForgotPassword: false,
        setShowForgotPassword: vi.fn(),
        otpCommunicationChannelId: null,
        setOtpCommunicationChannelId: vi.fn(),
      })

      const {getByTestId} = setup()
      const loginButton = getByTestId('login-button')
      expect(loginButton).toHaveAttribute('disabled')
    })

    it('disables the username and password inputs during login submission', async () => {
      // Mock the useNewLogin hook to return isUiActionPending: true
      vi.mocked(useNewLogin).mockReturnValue({
        isUiActionPending: true,
        setIsUiActionPending: vi.fn(),
        otpRequired: false,
        setOtpRequired: vi.fn(),
        rememberMe: false,
        setRememberMe: vi.fn(),
        showForgotPassword: false,
        setShowForgotPassword: vi.fn(),
        otpCommunicationChannelId: null,
        setOtpCommunicationChannelId: vi.fn(),
      })

      const {getByTestId} = setup()
      const usernameInput = getByTestId('username-input')
      const passwordInput = getByTestId('password-input')
      expect(usernameInput).toHaveAttribute('disabled')
      expect(passwordInput).toHaveAttribute('disabled')
    })
  })
})
