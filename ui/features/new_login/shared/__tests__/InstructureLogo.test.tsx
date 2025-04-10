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
import React from 'react'
import {InstructureLogo} from '..'
import {NewLoginDataProvider, NewLoginProvider, useNewLogin, useNewLoginData} from '../../context'

jest.mock('../assets/images/instructure.svg', () => 'mocked-image-path.svg')

jest.mock('../../context', () => {
  const originalModule = jest.requireActual('../../context')
  return {
    ...originalModule,
    useNewLogin: jest.fn(),
    useNewLoginData: jest.fn(),
  }
})

const mockUseNewLogin = useNewLogin as jest.Mock
const mockUseNewLoginData = useNewLoginData as jest.Mock

describe('InstructureLogo', () => {
  const renderInstructureLogo = () =>
    render(
      <NewLoginProvider>
        <NewLoginDataProvider>
          <InstructureLogo />
        </NewLoginDataProvider>
      </NewLoginProvider>,
    )

  beforeEach(() => {
    jest.clearAllMocks()
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseNewLoginData.mockReturnValue({isPreviewMode: false})
  })

  jest.mock('../assets/images/instructure.svg', () => 'mocked-image-path.svg')

  it('renders the InstructureLogo with correct attributes and structure', () => {
    renderInstructureLogo()
    const logoLink = screen.getByTestId('instructure-logo-link')
    expect(logoLink).toBeInTheDocument()
    expect(logoLink).toHaveAttribute('href', 'https://instructure.com')
    expect(logoLink).not.toHaveAttribute('target', '_blank')
    const logoImage = screen.getByTestId('instructure-logo-img')
    expect(logoImage).toBeInTheDocument()
    expect(logoImage).toHaveAttribute('src', 'mocked-image-path.svg')
    expect(logoImage).toHaveAttribute('alt', '')
  })

  it('ensures link does not have role button and is a valid anchor tag', () => {
    renderInstructureLogo()
    const link = screen.getByTestId('instructure-logo-link')
    expect(link).not.toHaveAttribute('role', 'button')
    expect(link).toHaveAttribute('href', 'https://instructure.com')
    expect(link.tagName).toBe('A')
  })

  it('ensures link has the correct accessible name and is not hidden or disabled', () => {
    renderInstructureLogo()
    const link = screen.getByLabelText('By Instructure')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('aria-label', 'By Instructure')
    expect(link).not.toHaveAttribute('aria-hidden')
    expect(link).not.toHaveAttribute('aria-disabled')
  })

  it('prevents navigation when disabled', async () => {
    mockUseNewLogin.mockReturnValue({isUiActionPending: true})
    mockUseNewLoginData.mockReturnValue({isPreviewMode: false})
    renderInstructureLogo()
    const link = screen.getByTestId('instructure-logo-link')
    const clickEvent = new MouseEvent('click', {bubbles: true, cancelable: true})
    jest.spyOn(clickEvent, 'preventDefault')
    link.dispatchEvent(clickEvent)
    expect(clickEvent.preventDefault).toHaveBeenCalled()
    expect(link).toHaveAttribute('href', 'https://instructure.com')
  })

  it('allows navigation when enabled', () => {
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseNewLoginData.mockReturnValue({isPreviewMode: false})
    renderInstructureLogo()
    const link = screen.getByTestId('instructure-logo-link')
    const clickEvent = new MouseEvent('click', {bubbles: true, cancelable: true})
    jest.spyOn(clickEvent, 'preventDefault')
    link.dispatchEvent(clickEvent)
    expect(link).toHaveAttribute('href', 'https://instructure.com')
    expect(clickEvent.preventDefault).not.toHaveBeenCalled()
  })

  it('ensures link navigates to the correct URL without opening a new tab', () => {
    renderInstructureLogo()
    const link = screen.getByTestId('instructure-logo-link')
    expect(link).toHaveAttribute('href', 'https://instructure.com')
    expect(link).not.toHaveAttribute('target')
  })
})
