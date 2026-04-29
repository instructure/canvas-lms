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

import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import {MemoryRouter} from 'react-router-dom'
import {NewLoginDataProvider, NewLoginProvider, useNewLoginData} from '../../../context'
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

describe('Student - form validation', () => {
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
    ;(useNewLoginData as ReturnType<typeof vi.fn>).mockImplementation(() => ({
      isDataLoading: false,
      privacyPolicyUrl: 'http://www.example.com/privacy',
      requireEmail: true,
      termsOfUseUrl: 'http://www.example.com/terms',
      termsRequired: true,
    }))
  })

  afterEach(() => {
    cleanup()
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
