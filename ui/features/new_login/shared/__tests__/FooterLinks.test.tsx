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

const mockHelpLink = {text: 'Help', trackCategory: 'test-category', trackLabel: 'test-label'}

describe('FooterLinks', () => {
  const renderFooterLinks = () =>
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <HelpTrayProvider>
            <FooterLinks />
          </HelpTrayProvider>
        </NewLoginProvider>
      </MemoryRouter>,
    )

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders without crashing', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: mockHelpLink,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    renderFooterLinks()
  })

  it('renders all links', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: mockHelpLink,
      requireAup: true,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    renderFooterLinks()
    expect(screen.getByTestId('help-link')).toBeInTheDocument()
    expect(screen.getByTestId('privacy-link')).toBeInTheDocument()
    expect(screen.getByTestId('cookie-notice-link')).toBeInTheDocument()
    expect(screen.getByTestId('aup-link')).toBeInTheDocument()
  })

  it('disables links when isDisabled is true', async () => {
    const mockOpenHelpTray = jest.fn()
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: true,
      helpLink: mockHelpLink,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: mockOpenHelpTray})
    renderFooterLinks()
    const helpLink = screen.getByTestId('help-link')
    await userEvent.click(helpLink)
    expect(mockOpenHelpTray).not.toHaveBeenCalled()
  })

  it('enables links when isDisabled is false', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: mockHelpLink,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    renderFooterLinks()
    const links = screen.getAllByTestId(/-link$/)
    links.forEach(link => {
      expect(link).not.toHaveAttribute('aria-disabled')
    })
  })

  it('opens help tray when help link is clicked', async () => {
    const mockOpenHelpTray = jest.fn()
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: mockHelpLink,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: mockOpenHelpTray})
    renderFooterLinks()
    const helpLink = screen.getByTestId('help-link')
    await userEvent.click(helpLink)
    expect(mockOpenHelpTray).toHaveBeenCalled()
  })

  it('renders tracking data for help link', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: mockHelpLink,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    renderFooterLinks()
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
    renderFooterLinks()
    const helpLink = screen.queryByTestId('help-link')
    expect(helpLink).toBeNull()
  })

  it('does not render acceptable use policy link if requireAup is not provided', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      requireAup: null,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    renderFooterLinks()
    const helpLink = screen.queryByTestId('aup-link')
    expect(helpLink).toBeNull()
  })

  it('renders links with correct semantics and no unnecessary roles or hrefs', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: mockHelpLink,
      requireAup: 'true',
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    renderFooterLinks()
    const helpLink = screen.getByTestId('help-link')
    expect(helpLink.tagName).toBe('BUTTON')
    expect(helpLink).not.toHaveAttribute('href')
    expect(helpLink).not.toHaveAttribute('role')
    const privacyLink = screen.getByTestId('privacy-link')
    expect(privacyLink.tagName).toBe('A')
    expect(privacyLink).toHaveAttribute('href', '/privacy_policy')
    expect(privacyLink).not.toHaveAttribute('role', 'button')
    const cookieNoticeLink = screen.getByTestId('cookie-notice-link')
    expect(cookieNoticeLink.tagName).toBe('A')
    expect(cookieNoticeLink).toHaveAttribute(
      'href',
      'https://www.instructure.com/policies/canvas-lms-cookie-notice',
    )
    expect(cookieNoticeLink).not.toHaveAttribute('role', 'button')
    const aupLink = screen.getByTestId('aup-link')
    expect(aupLink.tagName).toBe('A')
    expect(aupLink).toHaveAttribute('href', '/acceptable_use_policy')
    expect(aupLink).not.toHaveAttribute('role', 'button')
  })

  it('sets aria-expanded to false when tray is closed', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: mockHelpLink,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({
      openHelpTray: jest.fn(),
      closeHelpTray: jest.fn(),
      isHelpTrayOpen: false,
    })
    renderFooterLinks()
    expect(screen.getByTestId('help-link')).toHaveAttribute('aria-expanded', 'false')
  })

  it('sets aria-expanded to true when tray is open', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: mockHelpLink,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({
      openHelpTray: jest.fn(),
      closeHelpTray: jest.fn(),
      isHelpTrayOpen: true,
    })
    renderFooterLinks()
    expect(screen.getByTestId('help-link')).toHaveAttribute('aria-expanded', 'true')
  })

  it('ensures all links open in the same window (no target="_blank")', () => {
    mockUseNewLoginData.mockReturnValue({
      isPreviewMode: false,
      helpLink: mockHelpLink,
      requireAup: true,
    })
    mockUseNewLogin.mockReturnValue({isUiActionPending: false})
    mockUseHelpTray.mockReturnValue({openHelpTray: jest.fn()})
    renderFooterLinks()
    const links = screen.getAllByTestId(/-link$/)
    links.forEach(link => {
      expect(link).not.toHaveAttribute('target', '_blank')
    })
  })
})
