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
import {fireEvent, render, screen} from '@testing-library/react'
import React from 'react'
import {MemoryRouter} from 'react-router-dom'
import {ForgotPasswordLink} from '..'
import {NewLoginDataProvider, NewLoginProvider, useNewLogin, useNewLoginData} from '../../context'

jest.mock('../../context', () => {
  const originalModule = jest.requireActual('../../context')
  return {
    ...originalModule,
    useNewLogin: jest.fn(),
    useNewLoginData: jest.fn(),
  }
})

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

const mockUseNewLogin = useNewLogin as jest.Mock
const mockUseNewLoginData = useNewLoginData as jest.Mock

describe('ForgotPasswordLink', () => {
  const renderComponent = () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <ForgotPasswordLink />
          </NewLoginDataProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
  }

  beforeEach(() => {
    jest.clearAllMocks()
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseNewLoginData.mockReturnValue({isPreviewMode: false, forgotPasswordUrl: null})
  })

  it('renders without crashing', () => {
    renderComponent()
    expect(screen.getByText('Forgot password?')).toBeInTheDocument()
  })

  it('renders a link with forgotPasswordUrl when available', () => {
    const forgotPasswordUrl = 'https://example.com/reset-password'
    mockUseNewLoginData.mockReturnValue({isPreviewMode: false, forgotPasswordUrl})
    renderComponent()
    const button = screen.getByText('Forgot password?')
    expect(button.closest('a')).toHaveAttribute('href', forgotPasswordUrl)
  })

  it('renders a link to Canvas’ forgot password route when forgotPasswordUrl is not provided', () => {
    renderComponent()
    const button = screen.getByText('Forgot password?')
    expect(button.closest('a')).toHaveAttribute('href', '/login/canvas/forgot-password')
  })

  it('disables the button when isUiActionPending is true', () => {
    mockUseNewLogin.mockReturnValue({isUiActionPending: true})
    renderComponent()
    const button = screen.getByText('Forgot password?')
    fireEvent.click(button)
    expect(assignLocation).not.toHaveBeenCalled()
  })

  it('disables the button when isPreviewMode is true', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: true,
      forgotPasswordUrl: 'https://example.com/reset-password',
    })
    renderComponent()
    const button = screen.getByText('Forgot password?')
    fireEvent.click(button)
    expect(assignLocation).not.toHaveBeenCalled()
  })

  it('calls assignLocation when forgotPasswordUrl is provided and clicked', () => {
    const forgotPasswordUrl = 'https://example.com/reset-password'
    mockUseNewLoginData.mockReturnValue({isPreviewMode: false, forgotPasswordUrl})
    renderComponent()
    const button = screen.getByText('Forgot password?')
    fireEvent.click(button)
    expect(assignLocation).toHaveBeenCalledWith(forgotPasswordUrl)
  })
})
