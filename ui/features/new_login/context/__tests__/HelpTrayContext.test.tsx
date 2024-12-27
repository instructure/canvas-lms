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
import '@testing-library/jest-dom'
import {HelpTrayProvider, useHelpTray} from '..'

const TestComponent = () => {
  const {isHelpTrayOpen, openHelpTray, closeHelpTray} = useHelpTray()
  return (
    <div>
      <span data-testid="isHelpTrayOpen">{isHelpTrayOpen.toString()}</span>
      <button data-testid="openTrayButton" onClick={openHelpTray}>
        Open Tray
      </button>
      <button data-testid="closeTrayButton" onClick={closeHelpTray}>
        Close Tray
      </button>
    </div>
  )
}

describe('HelpTrayContext', () => {
  it('renders without crashing', () => {
    render(
      <HelpTrayProvider>
        <TestComponent />
      </HelpTrayProvider>,
    )
  })

  it('provides default value for isHelpTrayOpen as false', () => {
    render(
      <HelpTrayProvider>
        <TestComponent />
      </HelpTrayProvider>,
    )
    expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('false')
  })

  it('allows openHelpTray to set isHelpTrayOpen to true', () => {
    render(
      <HelpTrayProvider>
        <TestComponent />
      </HelpTrayProvider>,
    )
    const openButton = screen.getByTestId('openTrayButton')
    openButton.click()
    expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('true')
  })

  it('allows closeHelpTray to set isHelpTrayOpen to false', () => {
    render(
      <HelpTrayProvider>
        <TestComponent />
      </HelpTrayProvider>,
    )
    const openButton = screen.getByTestId('openTrayButton')
    const closeButton = screen.getByTestId('closeTrayButton')
    openButton.click()
    expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('true')
    closeButton.click()
    expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('false')
  })

  it('throws an error if useHelpTray is used outside HelpTrayProvider', () => {
    const OriginalConsoleError = console.error
    console.error = jest.fn()
    const renderOutsideProvider = () => {
      render(<TestComponent />)
    }
    expect(renderOutsideProvider).toThrow('useHelpTray must be used within a HelpTrayProvider')
    console.error = OriginalConsoleError
  })
})
