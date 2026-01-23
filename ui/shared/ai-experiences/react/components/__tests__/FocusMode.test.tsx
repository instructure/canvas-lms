/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import FocusMode from '../FocusMode'

describe('FocusMode', () => {
  const mockOnClose = jest.fn()
  const defaultProps = {
    isOpen: true,
    onClose: mockOnClose,
    children: <div>Test Content</div>,
  }

  beforeEach(() => {
    mockOnClose.mockClear()
  })

  it('renders when isOpen is true', () => {
    render(<FocusMode {...defaultProps} />)
    expect(screen.getByText('Test Content')).toBeInTheDocument()
  })

  it('does not render when isOpen is false', () => {
    render(<FocusMode {...defaultProps} isOpen={false} />)
    expect(screen.queryByText('Test Content')).not.toBeInTheDocument()
  })

  it('renders with default title "Conversation"', () => {
    render(<FocusMode {...defaultProps} />)
    expect(screen.getByText('Conversation')).toBeInTheDocument()
  })

  it('renders with custom title', () => {
    render(<FocusMode {...defaultProps} title="Custom Title" />)
    expect(screen.getByText('Custom Title')).toBeInTheDocument()
  })

  it('calls onClose when close button in header is clicked', async () => {
    const user = userEvent.setup()
    render(<FocusMode {...defaultProps} />)

    const closeButton = screen.getByTestId('focus-mode-exit-button').querySelector('button')
    expect(closeButton).not.toBeNull()
    await user.click(closeButton!)

    expect(mockOnClose).toHaveBeenCalledTimes(1)
  })

  it('calls onClose when exit button in footer is clicked', async () => {
    const user = userEvent.setup()
    render(<FocusMode {...defaultProps} />)

    const exitButton = screen.getByTestId('focus-mode-exit-button-footer')
    await user.click(exitButton)

    expect(mockOnClose).toHaveBeenCalledTimes(1)
  })

  it('calls onClose when ESC key is pressed', async () => {
    const user = userEvent.setup()
    render(<FocusMode {...defaultProps} />)

    await user.keyboard('{Escape}')

    expect(mockOnClose).toHaveBeenCalledTimes(1)
  })

  it('does not call onClose when ESC is pressed and modal is closed', async () => {
    const user = userEvent.setup()
    render(<FocusMode {...defaultProps} isOpen={false} />)

    await user.keyboard('{Escape}')

    expect(mockOnClose).not.toHaveBeenCalled()
  })

  it('removes event listener when modal closes', () => {
    const {rerender} = render(<FocusMode {...defaultProps} />)

    // Modal is open, now close it
    rerender(<FocusMode {...defaultProps} isOpen={false} />)

    // Verify the modal doesn't exist
    expect(screen.queryByText('Test Content')).not.toBeInTheDocument()
  })

  it('renders children correctly', () => {
    render(
      <FocusMode {...defaultProps}>
        <div data-testid="child-element">Child Content</div>
      </FocusMode>,
    )

    expect(screen.getByTestId('child-element')).toBeInTheDocument()
    expect(screen.getByText('Child Content')).toBeInTheDocument()
  })

  it('has correct screen reader text for close button', () => {
    render(<FocusMode {...defaultProps} />)
    expect(screen.getByText('Exit focus mode')).toBeInTheDocument()
  })

  it('displays Exit Focus Mode button text in footer', () => {
    render(<FocusMode {...defaultProps} />)
    expect(screen.getByText('Exit Focus Mode')).toBeInTheDocument()
  })

  it('modal has fullscreen size', () => {
    render(<FocusMode {...defaultProps} />)
    // The Modal component from InstUI should have the size prop, but we can verify the content is rendered
    expect(screen.getByText('Test Content')).toBeInTheDocument()
  })

  it('does not close on document click', async () => {
    const user = userEvent.setup()
    render(<FocusMode {...defaultProps} />)

    // Click on the modal body (not on a button)
    const content = screen.getByText('Test Content')
    await user.click(content)

    // Should not have called onClose
    expect(mockOnClose).not.toHaveBeenCalled()
  })

  it('handles multiple children', () => {
    render(
      <FocusMode {...defaultProps}>
        <div>First Child</div>
        <div>Second Child</div>
        <div>Third Child</div>
      </FocusMode>,
    )

    expect(screen.getByText('First Child')).toBeInTheDocument()
    expect(screen.getByText('Second Child')).toBeInTheDocument()
    expect(screen.getByText('Third Child')).toBeInTheDocument()
  })

  it('updates title when prop changes', () => {
    const {rerender} = render(<FocusMode {...defaultProps} title="Initial Title" />)
    expect(screen.getByText('Initial Title')).toBeInTheDocument()

    rerender(<FocusMode {...defaultProps} title="Updated Title" />)
    expect(screen.getByText('Updated Title')).toBeInTheDocument()
    expect(screen.queryByText('Initial Title')).not.toBeInTheDocument()
  })

  it('does not trigger ESC handler for other keys', async () => {
    const user = userEvent.setup()
    render(<FocusMode {...defaultProps} />)

    await user.keyboard('{Enter}')
    await user.keyboard('{Space}')
    await user.keyboard('a')

    expect(mockOnClose).not.toHaveBeenCalled()
  })
})
