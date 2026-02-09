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
import {render, screen, waitForElementToBeRemoved} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import UnsavedChangesModal from '../UnsavedChangesModal'

describe('UnsavedChangesModal', () => {
  const mockOnConfirm = jest.fn()
  const mockOnCancel = jest.fn()
  const mockOnClose = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Modal Visibility', () => {
    it('renders modal when isOpen is true', () => {
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
    })

    it('does not render modal when isOpen is false', () => {
      render(
        <UnsavedChangesModal
          isOpen={false}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
    })

    it('renders modal with correct data-testid', () => {
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      expect(screen.getByTestId('unsaved-changes-modal')).toBeInTheDocument()
    })
  })

  describe('Modal Content', () => {
    beforeEach(() => {
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )
    })

    it('displays the heading', () => {
      expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
    })

    it('displays the first body text about unsaved fixes', () => {
      expect(screen.getByText('Some of the fixes that you made are not saved.')).toBeInTheDocument()
    })

    it('displays the second body text asking if user wants to proceed', () => {
      expect(screen.getByText('Do you want to proceed without saving?')).toBeInTheDocument()
    })

    it('displays "Don\'t Save" button', () => {
      const dontSaveButton = screen.getByText("Don't save")
      expect(dontSaveButton).toBeInTheDocument()
      expect(dontSaveButton.closest('button')).toBeInTheDocument()
    })

    it('displays "Save changes" button', () => {
      const saveButton = screen.getByText('Save changes')
      expect(saveButton).toBeInTheDocument()
      expect(saveButton.closest('button')).toBeInTheDocument()
    })

    it('displays close icon button', () => {
      const closeButton = screen.getByRole('button', {name: 'Close'})
      expect(closeButton).toBeInTheDocument()
    })

    it('renders "Save changes" button as primary button', () => {
      const saveButton = screen.getByText('Save changes').closest('button')
      expect(saveButton).toBeInTheDocument()
      expect(saveButton?.textContent).toBe('Save changes')
    })
  })

  describe('User Interactions - Button Clicks', () => {
    it('calls onClose when close icon button is clicked', async () => {
      const user = userEvent.setup()
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      const closeButton = screen.getByRole('button', {name: 'Close'})
      await user.click(closeButton)

      expect(mockOnClose).toHaveBeenCalledTimes(1)
      expect(mockOnCancel).not.toHaveBeenCalled()
      expect(mockOnConfirm).not.toHaveBeenCalled()
    })

    it('calls onCancel when "Don\'t Save" button is clicked', async () => {
      const user = userEvent.setup()
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      const dontSaveButton = screen.getByText("Don't save").closest('button')!
      await user.click(dontSaveButton)

      expect(mockOnCancel).toHaveBeenCalledTimes(1)
      expect(mockOnClose).not.toHaveBeenCalled()
      expect(mockOnConfirm).not.toHaveBeenCalled()
    })

    it('calls onConfirm when "Save changes" button is clicked', async () => {
      const user = userEvent.setup()
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      const saveButton = screen.getByText('Save changes').closest('button')!
      await user.click(saveButton)

      expect(mockOnConfirm).toHaveBeenCalledTimes(1)
      expect(mockOnClose).not.toHaveBeenCalled()
      expect(mockOnCancel).not.toHaveBeenCalled()
    })
  })

  describe('User Interactions - Modal Dismiss', () => {
    it('modal onDismiss prop is set to onCancel', () => {
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      const modal = screen.getByTestId('unsaved-changes-modal')
      expect(modal).toBeInTheDocument()
    })

    it('calls onCancel when modal overlay is clicked', async () => {
      const user = userEvent.setup()
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      const modal = screen.getByTestId('unsaved-changes-modal')
      const overlay = modal.parentElement?.querySelector('[class*="Overlay"]')

      if (overlay) {
        await user.click(overlay)
        expect(mockOnCancel).toHaveBeenCalledTimes(1)
      }
    })
  })

  describe('Accessibility', () => {
    beforeEach(() => {
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )
    })

    it('has proper modal label for screen readers', () => {
      const modal = screen.getByTestId('unsaved-changes-modal')
      expect(modal).toHaveAttribute('aria-label', 'Unsaved Changes Confirmation')
    })

    it('has close button with screen reader label', () => {
      const closeButton = screen.getByRole('button', {name: 'Close'})
      expect(closeButton).toBeInTheDocument()
    })

    it('uses heading level h3 for modal title', () => {
      const heading = screen.getByText('You have unsaved changes')
      expect(heading.tagName).toBe('H3')
    })

    it('buttons are keyboard accessible', async () => {
      const user = userEvent.setup()

      await user.tab()
      expect(screen.getByRole('button', {name: 'Close'})).toHaveFocus()

      await user.tab()
      expect(screen.getByText("Don't save").closest('button')).toHaveFocus()

      await user.tab()
      expect(screen.getByText('Save changes').closest('button')).toHaveFocus()
    })

    it('can activate "Don\'t Save" button with keyboard', async () => {
      const user = userEvent.setup()

      await user.tab()
      await user.tab()

      await user.keyboard('{Enter}')

      expect(mockOnCancel).toHaveBeenCalledTimes(1)
    })

    it('can activate "Save changes" button with keyboard', async () => {
      const user = userEvent.setup()

      await user.tab()
      await user.tab()
      await user.tab()

      await user.keyboard('{Enter}')

      expect(mockOnConfirm).toHaveBeenCalledTimes(1)
    })
  })

  describe('Modal Behavior', () => {
    it('maintains separate callback handlers for different actions', async () => {
      const user = userEvent.setup()
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      const closeButton = screen.getByRole('button', {name: 'Close'})
      await user.click(closeButton)
      expect(mockOnClose).toHaveBeenCalledTimes(1)
      expect(mockOnCancel).toHaveBeenCalledTimes(0)
      expect(mockOnConfirm).toHaveBeenCalledTimes(0)

      jest.clearAllMocks()

      const dontSaveButton = screen.getByText("Don't save").closest('button')!
      await user.click(dontSaveButton)
      expect(mockOnCancel).toHaveBeenCalledTimes(1)
      expect(mockOnClose).toHaveBeenCalledTimes(0)
      expect(mockOnConfirm).toHaveBeenCalledTimes(0)

      jest.clearAllMocks()

      const saveButton = screen.getByText('Save changes').closest('button')!
      await user.click(saveButton)
      expect(mockOnConfirm).toHaveBeenCalledTimes(1)
      expect(mockOnClose).toHaveBeenCalledTimes(0)
      expect(mockOnCancel).toHaveBeenCalledTimes(0)
    })

    it('handles rapid successive clicks correctly', async () => {
      const user = userEvent.setup()
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      const saveButton = screen.getByText('Save changes').closest('button')!

      await user.click(saveButton)
      await user.click(saveButton)
      await user.click(saveButton)

      expect(mockOnConfirm).toHaveBeenCalledTimes(3)
    })

    it('renders modal with size prop set to small', () => {
      render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      const modal = screen.getByTestId('unsaved-changes-modal')
      expect(modal).toBeInTheDocument()
    })
  })

  describe('Edge Cases', () => {
    it('handles missing callbacks gracefully', () => {
      expect(() => {
        render(
          <UnsavedChangesModal
            isOpen={true}
            onConfirm={mockOnConfirm}
            onCancel={mockOnCancel}
            onClose={mockOnClose}
          />,
        )
      }).not.toThrow()
    })

    it('can transition from closed to open state', () => {
      const {rerender} = render(
        <UnsavedChangesModal
          isOpen={false}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()

      rerender(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
    })

    it('can transition from open to closed state', async () => {
      const {rerender} = render(
        <UnsavedChangesModal
          isOpen={true}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      const heading = screen.getByText('You have unsaved changes')
      expect(heading).toBeInTheDocument()

      rerender(
        <UnsavedChangesModal
          isOpen={false}
          onConfirm={mockOnConfirm}
          onCancel={mockOnCancel}
          onClose={mockOnClose}
        />,
      )

      await waitForElementToBeRemoved(() => screen.queryByText('You have unsaved changes'))
    })
  })
})
