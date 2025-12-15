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
import {cleanup, render, screen} from '@testing-library/react'
import {LoginLogo} from '..'
import {NewLoginProvider, NewLoginDataProvider, useNewLoginData} from '../../context'

vi.mock('../../context', async () => {
  const originalModule = await vi.importActual('../../context')
  return {
    ...originalModule,
    useNewLoginData: vi.fn(),
  }
})

const mockUseNewLoginData = vi.mocked(useNewLoginData)

const renderLoginLogo = () =>
  render(
    <NewLoginProvider>
      <NewLoginDataProvider>
        <LoginLogo />
      </NewLoginDataProvider>
    </NewLoginProvider>,
  )

describe('LoginLogo', () => {
  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders nothing when loginLogoUrl is not provided', () => {
    mockUseNewLoginData.mockReturnValue({
      isDataLoading: false,
      loginLogoUrl: '',
      loginLogoText: 'Canvas LMS',
    })
    renderLoginLogo()
    expect(screen.queryByTestId('login-logo-img')).not.toBeInTheDocument()
  })

  it('renders logo with correct src and alt text', () => {
    const alt = 'Canvas LMS'
    const src = 'https://example.com/logo.png'
    mockUseNewLoginData.mockReturnValue({
      isDataLoading: false,
      loginLogoUrl: src,
      loginLogoText: alt,
    })
    renderLoginLogo()
    const image = screen.getByTestId('login-logo-img')
    expect(image).toHaveAttribute('src', src)
    expect(image).toHaveAttribute('alt', alt)
  })

  it('renders logo with empty alt when loginLogoText is missing', () => {
    const src = 'https://example.com/logo.png'
    mockUseNewLoginData.mockReturnValue({
      isDataLoading: false,
      loginLogoUrl: src,
      loginLogoText: undefined,
    })
    renderLoginLogo()
    const image = screen.getByTestId('login-logo-img')
    expect(image).toHaveAttribute('src', src)
    expect(image).toHaveAttribute('alt', '')
  })
})
