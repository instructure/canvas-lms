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
import {waitFor} from '@testing-library/dom'
import {userEvent} from '@testing-library/user-event'
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
  let originalHash: string

  beforeEach(() => {
    originalHash = window.location.hash
    window.history.pushState(null, '', '/')
    window.dispatchEvent(new HashChangeEvent('hashchange'))
  })

  afterEach(() => {
    window.history.pushState(null, '', originalHash)
    window.dispatchEvent(new HashChangeEvent('hashchange'))
  })

  it('renders without crashing', () => {
    render(
      <HelpTrayProvider>
        <TestComponent />
      </HelpTrayProvider>,
    )
  })

  describe('initial state', () => {
    it('provides default value for isHelpTrayOpen as false', () => {
      render(
        <HelpTrayProvider>
          <TestComponent />
        </HelpTrayProvider>,
      )
      expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('false')
    })

    it('initializes isHelpTrayOpen to true if the hash is #help', () => {
      window.history.pushState(null, '', '#help')
      render(
        <HelpTrayProvider>
          <TestComponent />
        </HelpTrayProvider>,
      )
      expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('true')
    })

    it('initializes isHelpTrayOpen to false if the hash is not #help', () => {
      render(
        <HelpTrayProvider>
          <TestComponent />
        </HelpTrayProvider>,
      )
      expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('false')
    })
  })

  describe('state updates', () => {
    it('allows openHelpTray to set isHelpTrayOpen to true', async () => {
      render(
        <HelpTrayProvider>
          <TestComponent />
        </HelpTrayProvider>,
      )
      const openButton = screen.getByTestId('openTrayButton')
      await userEvent.click(openButton)
      expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('true')
    })

    it('allows closeHelpTray to set isHelpTrayOpen to false', async () => {
      render(
        <HelpTrayProvider>
          <TestComponent />
        </HelpTrayProvider>,
      )
      const openButton = screen.getByTestId('openTrayButton')
      await userEvent.click(openButton)
      expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('true')
      const closeButton = screen.getByTestId('closeTrayButton')
      await userEvent.click(closeButton)
      expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('false')
    })
  })

  describe('hash synchronization', () => {
    it('updates the hash to #help when openHelpTray is called', async () => {
      render(
        <HelpTrayProvider>
          <TestComponent />
        </HelpTrayProvider>,
      )
      const openButton = screen.getByTestId('openTrayButton')
      await userEvent.click(openButton)
      expect(window.location.hash).toBe('#help')
    })

    it('removes the hash when closeHelpTray is called', async () => {
      window.location.hash = '#help'
      render(
        <HelpTrayProvider>
          <TestComponent />
        </HelpTrayProvider>,
      )
      const closeButton = screen.getByTestId('closeTrayButton')
      await userEvent.click(closeButton)
      expect(window.location.hash).toBe('')
    })

    it('updates isHelpTrayOpen to true when the hash changes to #help', async () => {
      render(
        <HelpTrayProvider>
          <TestComponent />
        </HelpTrayProvider>,
      )
      expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('false')
      window.history.pushState(null, '', '#help')
      window.dispatchEvent(new HashChangeEvent('hashchange'))
      await waitFor(() => expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('true'))
    })

    it('updates isHelpTrayOpen to false when the hash changes away from #help', async () => {
      window.location.hash = '#help'
      render(
        <HelpTrayProvider>
          <TestComponent />
        </HelpTrayProvider>,
      )
      expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('true')
      window.location.hash = ''
      await waitFor(() => {
        expect(screen.getByTestId('isHelpTrayOpen')).toHaveTextContent('false')
      })
    })
  })

  describe('error handling', () => {
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
})
