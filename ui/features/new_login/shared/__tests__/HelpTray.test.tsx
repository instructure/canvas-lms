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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import HelpTray from '../HelpTray'
import {useHelpTray, useNewLoginData} from '../../context'
import {userEvent} from '@testing-library/user-event'

vi.mock('../../context', async () => {
  const originalModule = await vi.importActual('../../context')
  return {
    ...originalModule,
    useHelpTray: vi.fn(),
    useNewLoginData: vi.fn(),
  }
})

vi.mock('@canvas/help-dialog', () => ({
  __esModule: true,
  default: () => <div data-testid="help-dialog">Mocked HelpDialog</div>,
}))

const mockUseHelpTray = vi.mocked(useHelpTray)
const mockUseNewLoginData = vi.mocked(useNewLoginData)

const renderHelpTray = () => {
  const queryClient = new QueryClient()
  return render(
    <QueryClientProvider client={queryClient}>
      <HelpTray />
    </QueryClientProvider>,
  )
}

describe('HelpTray', () => {
  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
    mockUseNewLoginData.mockReturnValue({
      isDataLoading: false,
      helpLink: {text: 'Support', trackCategory: 'help', trackLabel: 'help_link'},
    })
  })

  it('renders the tray with heading text', () => {
    mockUseHelpTray.mockReturnValue({
      isHelpTrayOpen: true,
      openHelpTray: vi.fn(),
      closeHelpTray: vi.fn(),
    })
    renderHelpTray()
    expect(screen.getByText('Support')).toBeInTheDocument()
    expect(screen.getByTestId('help-tray')).toBeInTheDocument()
  })

  it('renders the HelpDialog inside the tray', () => {
    mockUseHelpTray.mockReturnValue({
      isHelpTrayOpen: true,
      openHelpTray: vi.fn(),
      closeHelpTray: vi.fn(),
    })
    renderHelpTray()
    expect(screen.getByTestId('help-dialog')).toBeInTheDocument()
  })

  it('calls closeHelpTray when CloseButton is clicked', async () => {
    const closeHelpTray = vi.fn()
    mockUseHelpTray.mockReturnValue({
      isHelpTrayOpen: true,
      openHelpTray: vi.fn(),
      closeHelpTray,
    })
    renderHelpTray()
    const wrapper = screen.getByTestId('close-help-tray-button')
    const button = wrapper.querySelector('button')
    expect(button).toBeTruthy()
    if (button) {
      await userEvent.click(button)
    }
    expect(closeHelpTray).toHaveBeenCalled()
  })

  it('does not render tray if isHelpTrayOpen is false', () => {
    mockUseHelpTray.mockReturnValue({
      isHelpTrayOpen: false,
      openHelpTray: vi.fn(),
      closeHelpTray: vi.fn(),
    })
    renderHelpTray()
    expect(screen.queryByTestId('help-tray')).not.toBeInTheDocument()
  })
})
