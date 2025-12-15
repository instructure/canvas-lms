/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import CanvasTray from '../Tray'
import {render, fireEvent} from '@testing-library/react'

describe('CanvasTray', () => {
  it('renders header, close button, children', () => {
    const handleDismiss = vi.fn()
    const {getByText} = render(
      <CanvasTray open={true} label="Do the thing" onDismiss={handleDismiss}>
        Tray Content
      </CanvasTray>,
    )
    expect(getByText('Do the thing').tagName).toBe('SPAN')
    expect(getByText('Tray Content')).toBeInTheDocument()
    const closeButton = getByText('Close').closest('button')
    expect(closeButton).toBeInTheDocument()
    fireEvent.click(closeButton)
    expect(handleDismiss).toHaveBeenCalled()
  })

  describe('Errors', () => {
    let originalError

    // Don't want to log the expected errors to the console
    beforeEach(() => {
      vi.spyOn(console, 'error').mockImplementation(() => {})

      // Also suppress window.onerror to prevent JSDOM from logging errors
      originalError = window.onerror
      window.onerror = () => true
    })

    afterEach(() => {
      console.error.mockRestore()

      // Restore window.onerror
      window.onerror = originalError
    })

    it('has an error boundary in case the children throw', () => {
      function ThrowError() {
        throw new Error('something bad happened')
      }

      const {getByText} = render(
        <CanvasTray open={true} label="Do the thing">
          <ThrowError />
        </CanvasTray>,
      )
      expect(getByText(/something broke/i)).toBeInTheDocument()
      // Header and close button should still be there
      expect(getByText('Do the thing').tagName).toBe('SPAN')
      expect(getByText('Close').closest('button')).toBeInTheDocument()
    })
  })
})
