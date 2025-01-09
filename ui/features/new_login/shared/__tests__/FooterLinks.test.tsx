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
import {MemoryRouter} from 'react-router-dom'
import {FooterLinks} from '..'
import {
  HelpTrayProvider,
  NewLoginProvider,
  useHelpTray,
  useNewLogin,
  useNewLoginData,
} from '../../context'

jest.mock('../../context', () => {
  const originalModule = jest.requireActual('../../context')
  return {
    ...originalModule,
    useNewLoginData: jest.fn(),
    useHelpTray: jest.fn(),
    useNewLogin: jest.fn(),
  }
})

const mockUseNewLoginData = useNewLoginData as jest.Mock
const mockUseHelpTray = useHelpTray as jest.Mock
const mockUseNewLogin = useNewLogin as jest.Mock

describe('FooterLinks', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders without crashing', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: {text: 'Help', trackCategory: 'test-category', trackLabel: 'test-label'},
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <HelpTrayProvider>
            <FooterLinks />
          </HelpTrayProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
  })

  it('renders all links', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: {text: 'Help', trackCategory: 'test-category', trackLabel: 'test-label'},
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <HelpTrayProvider>
            <FooterLinks />
          </HelpTrayProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    expect(screen.getByTestId('help-link')).toBeInTheDocument()
    expect(screen.getByTestId('privacy-link')).toBeInTheDocument()
    expect(screen.getByTestId('cookie-notice-link')).toBeInTheDocument()
    expect(screen.getByTestId('aup-link')).toBeInTheDocument()
  })

  it('disables links when isDisabled is true', async () => {
    const mockOpenHelpTray = jest.fn()
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: true,
      helpLink: {text: 'Help', trackCategory: 'test-category', trackLabel: 'test-label'},
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: mockOpenHelpTray})
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <HelpTrayProvider>
            <FooterLinks />
          </HelpTrayProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    const helpLink = screen.getByTestId('help-link')
    await userEvent.click(helpLink)
    expect(mockOpenHelpTray).not.toHaveBeenCalled()
  })

  it('enables links when isDisabled is false', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: {text: 'Help', trackCategory: 'test-category', trackLabel: 'test-label'},
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <HelpTrayProvider>
            <FooterLinks />
          </HelpTrayProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    const links = screen.getAllByTestId(/-link$/)
    links.forEach(link => {
      expect(link).not.toHaveAttribute('aria-disabled')
    })
  })

  it('opens help tray when help link is clicked', async () => {
    const mockOpenHelpTray = jest.fn()
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: {text: 'Help', trackCategory: 'test-category', trackLabel: 'test-label'},
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: mockOpenHelpTray})
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <HelpTrayProvider>
            <FooterLinks />
          </HelpTrayProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    const helpLink = screen.getByTestId('help-link')
    await userEvent.click(helpLink)
    expect(mockOpenHelpTray).toHaveBeenCalled()
  })

  it('renders tracking data for help link', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: {text: 'Help', trackCategory: 'test-category', trackLabel: 'test-label'},
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <HelpTrayProvider>
            <FooterLinks />
          </HelpTrayProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    const helpLink = screen.getByTestId('help-link')
    expect(helpLink).toHaveAttribute('data-track-category', 'test-category')
    expect(helpLink).toHaveAttribute('data-track-label', 'test-label')
  })

  it('does not render help link if helpLink is not provided', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: null,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <HelpTrayProvider>
            <FooterLinks />
          </HelpTrayProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )
    const helpLink = screen.queryByTestId('help-link')
    expect(helpLink).toBeNull()
  })
})
