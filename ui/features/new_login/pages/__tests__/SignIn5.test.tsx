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
import {cleanup, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLoginData} from '../../context'
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

// fickle
describe.skip('SignIn', () => {
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

  describe('ui State', () => {
    it('removes the error alert when the user starts typing in the username field', async () => {
      const {getByTestId} = setup()
      const usernameInput = getByTestId('username-input')
      const loginButton = getByTestId('login-button')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(usernameInput).toHaveAttribute('aria-invalid', 'true')
      })
      await userEvent.type(usernameInput, 'user@example.com')
      await waitFor(() => {
        expect(usernameInput).not.toHaveAttribute('aria-invalid', 'true')
      })
    })

    it('removes the error alert when the user starts typing in the password field', async () => {
      const {getByTestId} = setup()
      const usernameInput = getByTestId('username-input')
      const passwordInput = getByTestId('password-input')
      const loginButton = getByTestId('login-button')
      await userEvent.type(usernameInput, 'user@example.com')
      await userEvent.click(loginButton)
      await waitFor(() => {
        expect(passwordInput).toHaveAttribute('aria-invalid', 'true')
      })
      await userEvent.type(passwordInput, 'password123')
      await waitFor(() => {
        expect(passwordInput).not.toHaveAttribute('aria-invalid', 'true')
      })
    })
  })
})
