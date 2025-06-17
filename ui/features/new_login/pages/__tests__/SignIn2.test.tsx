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

  describe('redirects', () => {
    it('calls assignLocation with the correct URL after successful login', async () => {
      const setIsUiActionPending = jest.fn()
      ;(useNewLogin as jest.Mock).mockReturnValue({
        isUiActionPending: false,
        setIsUiActionPending,
        otpRequired: false,
        setOtpRequired: jest.fn(),
        rememberMe: false,
        setRememberMe: jest.fn(),
        loginFailed: false,
        setLoginFailed: jest.fn(),
      })
      ;(performSignIn as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {location: 'https://test.canvas.com/?login_success=1'},
      })
      setup()
      const usernameInput = screen.getByTestId('username-input')
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.type(passwordInput, 'password123')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(assignLocation).toHaveBeenCalledWith('https://test.canvas.com/?login_success=1')
        expect(assignLocation).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe('user input', () => {
    it('trims whitespace from the username field when typing', async () => {
      setup()
      const usernameInput = screen.getByTestId('username-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(usernameInput, '   user@example.com   ')
      await userEvent.click(loginButton)
      expect(usernameInput).toHaveValue('user@example.com')
      expect(usernameInput).not.toHaveValue('   user@example.com   ')
    })

    it('trims whitespace from the password field when typing', async () => {
      setup()
      const passwordInput = screen.getByTestId('password-input')
      const loginButton = screen.getByTestId('login-button')
      await userEvent.type(passwordInput, '   password123   ')
      await userEvent.click(loginButton)
      expect(passwordInput).toHaveValue('password123')
      expect(passwordInput).not.toHaveValue('   password123   ')
    })
  })
})
