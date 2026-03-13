/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import SignInPrompt from '../SignInPrompt'

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {...actual, useNavigate: vi.fn()}
})

const mockNavigate = vi.fn()

afterEach(() => {
  cleanup()
  vi.clearAllMocks()
})

beforeEach(() => {
  vi.mocked(useNavigate).mockReturnValue(mockNavigate)
})

describe('<SignInPrompt />', () => {
  it('renders prompt text and login link', () => {
    render(
      <MemoryRouter>
        <SignInPrompt />
      </MemoryRouter>,
    )
    expect(screen.getByText('Already have an account?')).toBeInTheDocument()
    const link = screen.getByTestId('log-in-link')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/login/canvas')
  })

  it('navigates to /login/canvas on click', async () => {
    render(
      <MemoryRouter>
        <SignInPrompt />
      </MemoryRouter>,
    )
    await userEvent.click(screen.getByTestId('log-in-link'))
    expect(mockNavigate).toHaveBeenCalledWith('/login/canvas')
  })
})
