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
import {render, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import HelpTray from '../HelpTray'
import {useHelpTray, useNewLoginData} from '../../context'
import {userEvent} from '@testing-library/user-event'

jest.mock('../../context', () => {
  const originalModule = jest.requireActual('../../context')
  return {
    ...originalModule,
    useHelpTray: jest.fn(),
    useNewLoginData: jest.fn(),
  }
})

jest.mock('@canvas/help-dialog', () => ({
  __esModule: true,
  default: () => <div data-testid="help-dialog">Mocked HelpDialog</div>,
}))

const mockUseHelpTray = useHelpTray as jest.Mock
const mockUseNewLoginData = useNewLoginData as jest.Mock

const renderHelpTray = () => {
  const queryClient = new QueryClient()
  return render(
    <QueryClientProvider client={queryClient}>
      <HelpTray />
    </QueryClientProvider>,
  )
}

describe('HelpTray', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockUseNewLoginData.mockReturnValue({helpLink: {text: 'Support'}})
  })

  it('renders the tray with heading text', () => {
    mockUseHelpTray.mockReturnValue({isHelpTrayOpen: true, closeHelpTray: jest.fn()})
    renderHelpTray()
    expect(screen.getByText('Support')).toBeInTheDocument()
    expect(screen.getByTestId('help-tray')).toBeInTheDocument()
  })

  it('renders the HelpDialog inside the tray', () => {
    mockUseHelpTray.mockReturnValue({isHelpTrayOpen: true, closeHelpTray: jest.fn()})
    renderHelpTray()
    expect(screen.getByTestId('help-dialog')).toBeInTheDocument()
  })

  it('calls closeHelpTray when CloseButton is clicked', async () => {
    const closeHelpTray = jest.fn()
    mockUseHelpTray.mockReturnValue({isHelpTrayOpen: true, closeHelpTray})
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
    mockUseHelpTray.mockReturnValue({isHelpTrayOpen: false, closeHelpTray: jest.fn()})
    renderHelpTray()
    expect(screen.queryByTestId('help-tray')).not.toBeInTheDocument()
  })
})
