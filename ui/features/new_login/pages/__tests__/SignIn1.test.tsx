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
import {cleanup, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLogin, useNewLoginData} from '../../context'
import {performSignIn} from '../../services'
import SignIn from '../SignIn'
import fakeENV from '@canvas/test-utils/fakeENV'

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
  performSignIn: jest.fn().mockResolvedValue({}),
  initiateOtpRequest: jest.fn(),
}))

jest.mock('@canvas/util/globalUtils', () => ({
  ...jest.requireActual('@canvas/util/globalUtils'),
  assignLocation: jest.fn(),
  windowPathname: jest.fn(),
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

  const mockNavigate = jest.fn()
  beforeAll(() => {
    ;(useNavigate as jest.Mock).mockReturnValue(mockNavigate)
  })

  beforeEach(() => {
    fakeENV.setup()
    jest.clearAllMocks()
    jest.restoreAllMocks()
    // reset the mock implementation to return the default values
    ;(useNewLoginData as jest.Mock).mockImplementation(() => ({
      loginHandleName: 'Email',
    }))
  })

  afterEach(() => {
    cleanup()
    fakeENV.teardown()
  })

  describe('login behavior', () => {
    // fickle
    it.skip('calls performSignIn with /login/canvas when on the Canvas login route', async () => {
      ;(windowPathname as jest.Mock).mockReturnValue('/login/canvas')
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

    it.skip('calls performSignIn with /login/ldap when on the LDAP login route', async () => {
      ;(windowPathname as jest.Mock).mockReturnValue('/login/ldap')
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

    // fickle
    it.skip('displays a login error alert when invalid credentials are submitted', async () => {
      ;(performSignIn as jest.Mock).mockRejectedValueOnce({response: {status: 400}})
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        loginFailed: true,
        setLoginFailed: jest.fn(),
      })

      const {getByTestId} = setup()
      const usernameInput = getByTestId('username-input')
      const passwordInput = getByTestId('password-input')
      const loginButton = getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'wrongpassword')
      await userEvent.click(loginButton)

      // Wait for the login to fail and check if the error message appears
      await waitFor(() => {
        expect(getByTestId('login-error-alert')).toBeInTheDocument()
      })
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
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: true,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })

      const {getByTestId} = setup()
      const loginButton = getByTestId('login-button')
      expect(loginButton).toHaveAttribute('disabled')
    })

    it('disables the username and password inputs during login submission', async () => {
      // Mock the useNewLogin hook to return isUiActionPending: true
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: true,
        setIsUiActionPending: jest.fn(),
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })

      const {getByTestId} = setup()
      const usernameInput = getByTestId('username-input')
      const passwordInput = getByTestId('password-input')
      expect(usernameInput).toHaveAttribute('disabled')
      expect(passwordInput).toHaveAttribute('disabled')
    })
  })
})
