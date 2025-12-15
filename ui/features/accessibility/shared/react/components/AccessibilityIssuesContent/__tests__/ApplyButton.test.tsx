/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ApplyButton from '../ApplyButton'

describe('ApplyButton', () => {
  afterEach(() => {
    cleanup()
  })

  const defaultProps = {
    children: 'Apply',
    onApply: vi.fn(),
    onUndo: vi.fn(),
    isApplied: false,
    isLoading: false,
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('when not applied', () => {
    it('renders apply button with correct text', () => {
      render(<ApplyButton {...defaultProps} />)

      expect(screen.getByTestId('apply-button')).toBeInTheDocument()
      expect(screen.queryByText('Issue fixed')).not.toBeInTheDocument()
    })

    it('calls onApply when apply button is clicked', async () => {
      render(<ApplyButton {...defaultProps} />)

      const applyButton = screen.getByTestId('apply-button')
      await userEvent.click(applyButton)

      expect(defaultProps.onApply).toHaveBeenCalledTimes(1)
    })

    it('shows loading state when isLoading is true', () => {
      render(<ApplyButton {...defaultProps} isLoading={true} />)

      const applyButton = screen.getByTestId('apply-button')
      expect(applyButton).toBeInTheDocument()
      expect(applyButton).toBeDisabled()
    })

    it('disables button when isLoading is true', () => {
      render(<ApplyButton {...defaultProps} isLoading={true} />)

      const applyButton = screen.getByTestId('apply-button')
      expect(applyButton).toBeDisabled()
    })

    it('does not call onApply when button is disabled', async () => {
      render(<ApplyButton {...defaultProps} isLoading={true} />)

      const applyButton = screen.getByTestId('apply-button')
      await userEvent.click(applyButton)

      expect(defaultProps.onApply).not.toHaveBeenCalled()
    })
  })

  describe('when applied', () => {
    const appliedProps = {
      ...defaultProps,
      isApplied: true,
    }

    it('renders undo button with success icon and text', () => {
      render(<ApplyButton {...appliedProps} />)

      expect(screen.getByText('Issue fixed')).toBeInTheDocument()
      expect(screen.getByTestId('undo-button')).toBeInTheDocument()
      expect(screen.queryByTestId('apply-button')).not.toBeInTheDocument()
    })

    it('calls onUndo when undo button is clicked', async () => {
      render(<ApplyButton {...appliedProps} />)

      const undoButton = screen.getByTestId('undo-button')
      await userEvent.click(undoButton)

      expect(defaultProps.onUndo).toHaveBeenCalledTimes(1)
    })

    it('shows loading state when isLoading is true', () => {
      render(<ApplyButton {...appliedProps} isLoading={true} />)

      const undoButton = screen.getByTestId('undo-button')
      expect(undoButton).toBeInTheDocument()
      expect(undoButton).toBeDisabled()
    })

    it('disables undo button when isLoading is true', () => {
      render(<ApplyButton {...appliedProps} isLoading={true} />)

      const undoButton = screen.getByTestId('undo-button')
      expect(undoButton).toBeDisabled()
    })

    it('does not call onUndo when button is disabled', async () => {
      render(<ApplyButton {...appliedProps} isLoading={true} />)

      const undoButton = screen.getByTestId('undo-button')
      await userEvent.click(undoButton)

      expect(defaultProps.onUndo).not.toHaveBeenCalled()
    })
  })

  describe('auto-focus after action', () => {
    it('focuses undo button after applying', async () => {
      const {rerender} = render(<ApplyButton {...defaultProps} />)

      const applyButton = screen.getByTestId('apply-button')
      await userEvent.click(applyButton)

      // Simulate the state change after applying
      rerender(<ApplyButton {...defaultProps} isApplied={true} />)

      await waitFor(() => {
        const undoButton = screen.getByTestId('undo-button')
        expect(undoButton).toHaveFocus()
      })
    })

    it('focuses apply button after undoing', async () => {
      const {rerender} = render(<ApplyButton {...defaultProps} isApplied={true} />)

      const undoButton = screen.getByTestId('undo-button')
      await userEvent.click(undoButton)

      // Simulate the state change after undoing
      rerender(<ApplyButton {...defaultProps} isApplied={false} />)

      await waitFor(() => {
        const applyButton = screen.getByTestId('apply-button')
        expect(applyButton).toHaveFocus()
      })
    })

    it('does not auto-focus when no action has been performed', () => {
      render(<ApplyButton {...defaultProps} />)

      const applyButton = screen.getByTestId('apply-button')
      expect(applyButton).not.toHaveFocus()
    })
  })
})
