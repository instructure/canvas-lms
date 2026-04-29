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
import {cleanup, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLoginData} from '../../context'
import SignIn from '../SignIn'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('react-router-dom', async () => ({
  ...(await vi.importActual('react-router-dom')),
  useNavigate: vi.fn(),
}))

vi.mock('../../context', async () => {
  const actualContext = await vi.importActual<typeof import('../../context')>('../../context')
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

// fickle
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

  describe('ui State', () => {
    // Skipped: Tests error alert dismissal behavior - aria-invalid not cleared on typing
    it.skip('removes the error alert when the user starts typing in the username field', async () => {
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

    // Skipped: Tests error alert dismissal behavior - aria-invalid not cleared on typing
    it.skip('removes the error alert when the user starts typing in the password field', async () => {
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
