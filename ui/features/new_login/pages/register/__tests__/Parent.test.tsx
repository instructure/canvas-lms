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
import {within} from '@testing-library/dom'
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import {MemoryRouter, useLocation, useNavigate, useNavigationType} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLoginData} from '../../../context'
import {createParentAccount} from '../../../services'
import Parent from '../Parent'

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: jest.fn(),
  useNavigationType: jest.fn(),
  useLocation: jest.fn(),
}))

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

jest.mock('../../../services', () => ({
  createParentAccount: jest.fn(),
}))

jest.mock('../../../context', () => {
  const actualContext = jest.requireActual('../../../context')
  return {
    ...actualContext,
    useNewLoginData: jest.fn(() => ({
      ...actualContext.useNewLoginData(),
    })),
  }
})

describe('Parent', () => {
  const setup = () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <Parent />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
  }

  const mockNavigate = jest.fn()
  const mockNavigationType = useNavigationType as jest.Mock
  const mockLocation = useLocation as jest.Mock
  beforeAll(() => {
    ;(useNavigate as jest.Mock).mockReturnValue(mockNavigate)
  })

  beforeEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
    // reset the mock implementation to return the default values
    ;(useNewLoginData as jest.Mock).mockImplementation(() => ({
      loginHandleName: 'Email',
      privacyPolicyUrl: '',
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
      expect(await screen.findByTestId('email-input')).toBeInTheDocument()
      expect(screen.getByTestId('password-input')).toBeInTheDocument()
      expect(screen.getByTestId('confirm-password-input')).toBeInTheDocument()
      expect(screen.getByTestId('name-input')).toBeInTheDocument()
      expect(screen.getByTestId('pairing-code-input')).toBeInTheDocument()
      expect(screen.getByTestId('pairing-code-link')).toBeInTheDocument()
      expect(screen.queryByTestId('terms-and-policy-checkbox')).not.toBeInTheDocument()
    })

    it('renders terms checkbox when required', async () => {
      ;(useNewLoginData as jest.Mock).mockImplementation(() => ({
        ...jest.requireActual('../../../context').useNewLoginData(),
        termsRequired: true,
        privacyPolicyUrl: 'http://www.example.com/privacy',
        termsOfUseUrl: 'http://www.example.com/terms',
      }))
      setup()
      expect(await screen.findByTestId('terms-and-policy-checkbox')).toBeInTheDocument()
    })
  })

  describe('form validation', () => {
    it('shows an error for an invalid email and focuses the email input', async () => {
      setup()
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Please enter a valid email address.')).toBeInTheDocument()
      expect(document.activeElement).toBe(screen.getByTestId('email-input'))
      await userEvent.type(screen.getByTestId('email-input'), 'valid@example.com')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Please enter a valid email address.')).not.toBeInTheDocument()
    })

    it('shows an error when the password is missing', async () => {
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'valid@example.com')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Password is required.')).toBeInTheDocument()
      expect(document.activeElement).toBe(screen.getByTestId('password-input'))
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Password is required.')).not.toBeInTheDocument()
    })

    it('validates that passwords match', async () => {
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'valid@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'MismatchPassword')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Passwords do not match.')).toBeInTheDocument()
      await userEvent.clear(screen.getByTestId('confirm-password-input'))
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Passwords do not match.')).not.toBeInTheDocument()
    })

    it('validates the name field', async () => {
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'valid@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Name is required.')).toBeInTheDocument()
      await userEvent.type(screen.getByTestId('name-input'), 'John Doe')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Name is required.')).not.toBeInTheDocument()
    })

    it('validates the pairing code field', async () => {
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'valid@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('name-input'), 'John Doe')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Pairing code is required.')).toBeInTheDocument()
      await userEvent.type(screen.getByTestId('pairing-code-input'), 'PAIR123')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Pairing code is required.')).not.toBeInTheDocument()
    })

    it('validates the terms checkbox when required', async () => {
      ;(useNewLoginData as jest.Mock).mockImplementation(() => ({
        termsRequired: true,
        privacyPolicyUrl: 'http://www.example.com/privacy',
        termsOfUseUrl: 'http://www.example.com/terms',
      }))
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'valid@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('name-input'), 'John Doe')
      await userEvent.type(screen.getByTestId('pairing-code-input'), 'PAIR123')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(
        await screen.findByText('You must accept the terms to create an account.'),
      ).toBeInTheDocument()
      await userEvent.click(screen.getByTestId('terms-and-policy-checkbox'))
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(
        screen.queryByText('You must accept the terms to create an account.'),
      ).not.toBeInTheDocument()
    })

    it('does not clear the name error until submit is clicked again', async () => {
      setup()
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('Name is required.')).toBeInTheDocument()
      await userEvent.type(screen.getByTestId('name-input'), 'John Doe')
      expect(screen.queryByText('Name is required.')).toBeInTheDocument()
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(screen.queryByText('Name is required.')).not.toBeInTheDocument()
    })
  })

  describe('form submission', () => {
    it('submits successfully with valid inputs', async () => {
      ;(createParentAccount as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {redirect_url: '/dashboard'},
      })
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'parent@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('name-input'), 'Parent User')
      await userEvent.type(screen.getByTestId('pairing-code-input'), 'PAIR123')
      await userEvent.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(createParentAccount).toHaveBeenCalledWith({
          email: 'parent@example.com',
          password: 'ValidPassword123!',
          confirmPassword: 'ValidPassword123!',
          name: 'Parent User',
          pairingCode: 'PAIR123',
          termsAccepted: false,
        })
      })
    })

    it('shows error messages for failed API validation', async () => {
      ;(createParentAccount as jest.Mock).mockRejectedValueOnce({
        response: {
          json: async () => ({
            errors: {
              pseudonym: {unique_id: [{type: 'taken'}]},
              pairing_code: {code: [{type: 'invalid'}]},
            },
          }),
        },
      })
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'existing@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('name-input'), 'Parent User')
      await userEvent.type(screen.getByTestId('pairing-code-input'), 'INVALID')
      await userEvent.click(screen.getByTestId('submit-button'))
      expect(await screen.findByText('This username is already in use.')).toBeInTheDocument()
      expect(screen.getByText('The pairing code is invalid.')).toBeInTheDocument()
    })

    it('handles generic server errors gracefully', async () => {
      ;(createParentAccount as jest.Mock).mockRejectedValueOnce({
        response: {
          status: 500,
          json: async () => ({}),
        },
      })
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'parent@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('name-input'), 'Parent User')
      await userEvent.type(screen.getByTestId('pairing-code-input'), 'PAIR123')
      await userEvent.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        const alertContainer = document.querySelector('.flashalert-message') as HTMLElement
        const flashAlert = within(alertContainer!).getByText(
          'Something went wrong. Please try again later.',
        )
        expect(flashAlert).toBeInTheDocument()
      })
    })

    it('redirects to the provided destination after a successful submission', async () => {
      ;(createParentAccount as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {destination: '/custom-redirect'},
      })
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'parent@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('name-input'), 'Parent User')
      await userEvent.type(screen.getByTestId('pairing-code-input'), 'PAIR123')
      await userEvent.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(assignLocation).toHaveBeenCalledWith('/custom-redirect')
      })
    })

    it('redirects to the course page if course data is provided', async () => {
      ;(createParentAccount as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {course: {course: {id: 42}}},
      })
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'parent@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('name-input'), 'Parent User')
      await userEvent.type(screen.getByTestId('pairing-code-input'), 'PAIR123')
      await userEvent.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(assignLocation).toHaveBeenCalledWith('/courses/42?registration_success=1')
      })
    })

    it('redirects to the default location if no destination or course is provided', async () => {
      ;(createParentAccount as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {},
      })
      setup()
      await userEvent.type(screen.getByTestId('email-input'), 'parent@example.com')
      await userEvent.type(screen.getByTestId('password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('confirm-password-input'), 'ValidPassword123!')
      await userEvent.type(screen.getByTestId('name-input'), 'Parent User')
      await userEvent.type(screen.getByTestId('pairing-code-input'), 'PAIR123')
      await userEvent.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(assignLocation).toHaveBeenCalledWith('/?registration_success=1')
      })
    })
  })

  describe('navigation behavior', () => {
    describe('when the cancel button is clicked', () => {
      it('navigates back to login when there is no previous history', async () => {
        mockNavigationType.mockReturnValue('POP')
        mockLocation.mockReturnValue({key: 'default'})
        setup()
        const backButton = screen.getByTestId('back-button')
        await userEvent.click(backButton)
        expect(mockNavigate).toHaveBeenCalledWith('/login/canvas')
        expect(mockNavigate).toHaveBeenCalledTimes(1)
      })

      it('navigates back to the previous page when history exists', async () => {
        mockNavigationType.mockReturnValue('PUSH')
        mockLocation.mockReturnValue({key: 'abc123'}) // non-default key
        ;(useNavigate as jest.Mock).mockReturnValue(mockNavigate)
        setup()
        const backButton = screen.getByTestId('back-button')
        await userEvent.click(backButton)
        expect(mockNavigate).toHaveBeenCalledWith(-1)
        expect(mockNavigate).toHaveBeenCalledTimes(1)
      })

      it('navigates to fallback when navigationType is POP or key is default', async () => {
        mockNavigationType.mockReturnValue('POP')
        mockLocation.mockReturnValue({key: 'default'})
        ;(useNavigate as jest.Mock).mockReturnValue(mockNavigate)
        setup()
        const backButton = screen.getByTestId('back-button')
        await userEvent.click(backButton)
        expect(mockNavigate).toHaveBeenCalledWith('/login/canvas')
      })
    })
  })
})
