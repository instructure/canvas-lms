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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import CanvasModal from '../Modal'

describe('CanvasModal', () => {
  it('renders a header, close button, and children', async () => {
    const handleDismiss = jest.fn()
    render(
      <CanvasModal
        open={true}
        label="Do the thing"
        onDismiss={handleDismiss}
        footer={<span>The Footer</span>}
      >
        Dialog Content
      </CanvasModal>,
    )

    const heading = screen.getByRole('heading', {name: 'Do the thing'})
    expect(heading.tagName).toBe('H2')
    expect(screen.getByText('Dialog Content')).toBeInTheDocument()
    expect(screen.getByText('The Footer')).toBeInTheDocument()

    const closeButton = screen.getByRole('button', {name: 'Close'})
    expect(closeButton).toBeInTheDocument()
    await userEvent.click(closeButton)
    expect(handleDismiss).toHaveBeenCalled()
  })

  describe('Error Boundary', () => {
    const originalError = console.error
    beforeAll(() => {
      console.error = jest.fn()
    })

    afterAll(() => {
      console.error = originalError
    })

    it('catches errors in children and displays fallback UI', () => {
      const ThrowError = () => {
        throw new Error('something bad happened')
      }

      render(
        <CanvasModal open={true} label="Do the thing">
          <ThrowError />
        </CanvasModal>,
      )

      expect(screen.getByText(/something broke/i)).toBeInTheDocument()
      expect(screen.getByRole('heading', {name: 'Do the thing'})).toBeInTheDocument()
      expect(screen.getByRole('button', {name: 'Close'})).toBeInTheDocument()
    })
  })
})
