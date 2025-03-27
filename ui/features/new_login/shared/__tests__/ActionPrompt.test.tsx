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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import {MemoryRouter, useNavigate} from 'react-router-dom'
import {ActionPrompt} from '..'
import {NewLoginDataProvider, NewLoginProvider} from '../../context'

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: jest.fn(),
}))

describe('ActionPrompt', () => {
  const mockNavigate = jest.fn()

  beforeEach(() => {
    ;(useNavigate as jest.Mock).mockReturnValue(mockNavigate)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('mounts without crashing', () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <ActionPrompt variant="signIn" />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
  })

  it('renders the correct text and link for "signIn" variant', () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <ActionPrompt variant="signIn" />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    expect(screen.getByText('Already have an account?')).toBeInTheDocument()
    const link = screen.getByText('Log in')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/login/canvas')
    expect(screen.queryByText('Log in or')).not.toBeInTheDocument()
  })

  it('renders the correct text and link for "createAccount" variant', () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <ActionPrompt variant="createAccount" />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    expect(screen.getByText('Log in or')).toBeInTheDocument()
    const link = screen.getByText('create an account.')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/login/canvas/register')
    expect(screen.queryByText('Already have an account?')).not.toBeInTheDocument()
  })

  it('renders the correct text and link for "createParentAccount" variant', () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <ActionPrompt variant="createParentAccount" />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    expect(screen.getByText('Have a pairing code?')).toBeInTheDocument()
    const link = screen.getByText('Create a Parent Account')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/login/canvas/register/parent')
    expect(screen.queryByText('Log in or')).not.toBeInTheDocument()
  })

  it('renders nothing for an invalid variant', () => {
    const {container} = render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            {/* @ts-expect-error intentionally passing an invalid variant */}
            <ActionPrompt variant="invalidVariant" />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    expect(container.firstChild).toBeNull()
  })

  it('invokes the navigation handler when a link is clicked', async () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <ActionPrompt variant="signIn" />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    const link = screen.getByText('Log in')
    await userEvent.click(link)
    expect(mockNavigate).toHaveBeenCalledWith('/login/canvas')
    expect(mockNavigate).toHaveBeenCalledTimes(1)
  })
})
