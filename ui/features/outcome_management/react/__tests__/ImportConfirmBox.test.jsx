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
import {render, screen, act, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ImportConfirmBox, {showImportConfirmBox} from '../ImportConfirmBox'

jest.useFakeTimers()

describe('ImportConfirmBox', () => {
  let alertDiv
  const onCloseHandlerMock = jest.fn()
  const onImportHandlerMock = jest.fn()
  const defaultProps = (props = {}) => ({
    count: 100,
    onCloseHandler: onCloseHandlerMock,
    onImportHandler: onImportHandlerMock,
    ...props,
  })

  // Custom render function to help with testing
  const renderImportConfirmBox = props => {
    // Clear any previous renders
    if (document.body.querySelector('[data-testid="import-confirm-box"]')) {
      document.body.innerHTML = ''
    }

    return render(<ImportConfirmBox {...defaultProps(props)} />)
  }

  beforeEach(() => {
    // Reset the DOM between tests
    document.body.innerHTML = ''

    // Create the alert div fresh for each test
    alertDiv = document.createElement('div')
    alertDiv.id = 'flashalert_message_holder'
    alertDiv.setAttribute('role', 'alert')
    alertDiv.setAttribute('aria-live', 'assertive')
    alertDiv.setAttribute('aria-relevant', 'additions text')
    alertDiv.setAttribute('aria-atomic', 'false')
    document.body.appendChild(alertDiv)
  })

  afterEach(() => {
    // Clean up after each test
    jest.clearAllMocks()
    document.body.innerHTML = ''
    alertDiv = null
  })

  describe('ImportConfirmBox', () => {
    it('shows message with number of outcomes to be imported', () => {
      // Update the component to add data-testid
      const ImportConfirmBoxWithTestId = props => (
        <div data-testid="import-confirm-box">
          <ImportConfirmBox {...props} />
        </div>
      )

      render(<ImportConfirmBoxWithTestId {...defaultProps()} />)

      // Use a more specific query with container
      const container = screen.getByTestId('import-confirm-box')
      const message = container.querySelector('div[class*="text"]')
      expect(message.textContent).toBe('You are about to add 100 outcomes to this course.')
    })

    it('pluralizes message depending on number of outcomes to be imported', () => {
      // Update the component to add data-testid
      const ImportConfirmBoxWithTestId = props => (
        <div data-testid="import-confirm-box">
          <ImportConfirmBox {...props} />
        </div>
      )

      render(<ImportConfirmBoxWithTestId {...defaultProps({count: 1})} />)

      // Use a more specific query with container
      const container = screen.getByTestId('import-confirm-box')
      const message = container.querySelector('div[class*="text"]')
      expect(message.textContent).toBe('You are about to add 1 outcome to this course.')
    })

    it('calls onCloseHandler when cancel button is clicked', async () => {
      // Update the component to add data-testid
      const ImportConfirmBoxWithTestId = props => (
        <div data-testid="import-confirm-box">
          <ImportConfirmBox {...props} />
        </div>
      )

      render(<ImportConfirmBoxWithTestId {...defaultProps()} />)

      // Use a more specific query with container and role
      const container = screen.getByTestId('import-confirm-box')
      const cancelButton = container.querySelector('button span span').closest('button')
      fireEvent.click(cancelButton)

      await act(async () => jest.runAllTimers())
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })

    it('calls onImportHandler and onCloseHandler when Import Anyway button is clicked', async () => {
      // Update the component to add data-testid
      const ImportConfirmBoxWithTestId = props => (
        <div data-testid="import-confirm-box">
          <ImportConfirmBox {...props} />
        </div>
      )

      render(<ImportConfirmBoxWithTestId {...defaultProps()} />)

      // Find the button by its text content within the container
      const container = screen.getByTestId('import-confirm-box')
      const buttons = container.querySelectorAll('button')
      const importButton = Array.from(buttons).find(button =>
        button.textContent.includes('Import Anyway'),
      )

      fireEvent.click(importButton)
      await act(async () => jest.runAllTimers())
      expect(onImportHandlerMock).toHaveBeenCalled()
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })
  })

  describe('showImportConfirmBox', () => {
    it('renders ImportConfirmBox when showImportConfirmBox is called', async () => {
      showImportConfirmBox({...defaultProps()})
      expect(
        screen.getByText(/You are about to add 100 outcomes to this course./),
      ).toBeInTheDocument()
    })

    it('calls onCloseHandler before ImportConfirmBox is unmounted', async () => {
      showImportConfirmBox({...defaultProps()})
      fireEvent.click(screen.getByText('Cancel'))
      await act(async () => jest.runAllTimers())
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })

    it('creates div element for mounting the ImportConfirmBox', async () => {
      alertDiv.remove()
      showImportConfirmBox({...defaultProps()})
      expect(document.getElementById('flashalert_message_holder')).not.toBeNull()
    })
  })
})
