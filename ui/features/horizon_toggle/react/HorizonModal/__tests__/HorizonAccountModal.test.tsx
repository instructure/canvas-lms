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

import {render, screen, fireEvent} from '@testing-library/react'
import {AccountChangeModal} from '../HorizonAccountModal'
import {useCanvasCareer} from '../../hooks/useCanvasCareer'

jest.mock('../../hooks/useCanvasCareer')

describe('HorizonAccountModal', () => {
  const mockOnClose = jest.fn()
  const mockOnConfirm = jest.fn()
  const mockOnSubmit = jest.fn()
  const mockSetTermsAccepted = jest.fn()

  const defaultHookReturn = {
    data: {},
    loading: false,
    hasUnsupportedContent: false,
    hasChangesNeededContent: false,
    loadingText: '',
    isTermsAccepted: false,
    setTermsAccepted: mockSetTermsAccepted,
    progress: {},
    onSubmit: mockOnSubmit,
  }

  beforeEach(() => {
    jest.clearAllMocks()
    ;(useCanvasCareer as jest.Mock).mockReturnValue(defaultHookReturn)
  })

  const setup = (propOverrides = {}, hookOverrides = {}) => {
    ;(useCanvasCareer as jest.Mock).mockReturnValue({
      ...defaultHookReturn,
      ...hookOverrides,
    })

    const props = {
      isOpen: true,
      onClose: mockOnClose,
      onConfirm: mockOnConfirm,
      ...propOverrides,
    }

    return render(<AccountChangeModal {...props} />)
  }

  it('renders the modal', () => {
    setup()
    expect(screen.getByText('Canvas Career Sub-Account')).toBeInTheDocument()
  })

  it('calls onClose when the Cancel button is clicked', () => {
    setup()
    const cancelButton = screen.getByText('Cancel')
    fireEvent.click(cancelButton)
    expect(mockOnClose).toHaveBeenCalledTimes(1)
  })

  it('shows ContentUnsupported when hasUnsupportedContent is true', () => {
    setup({}, {hasUnsupportedContent: true})
    expect(
      screen.getByText(/These content types will not be available in Canvas Career./i),
    ).toBeInTheDocument()
  })

  it('shows ContentChanges when hasChangesNeededContent is true', () => {
    setup({}, {hasChangesNeededContent: true})
    expect(
      screen.getByText(
        /In order to convert your course to Canvas Career, the following changes will be made to existing course content./i,
      ),
    ).toBeInTheDocument()
  })

  it('shows success message when no issues are found', () => {
    setup()
    expect(
      screen.getByText(
        'All existing course content is supported. Your course is ready to convert to Canvas Career.',
      ),
    ).toBeInTheDocument()
  })

  it('toggles terms acceptance when checkbox is clicked', () => {
    setup()
    const checkbox = screen.getByLabelText(
      /I acknowledge that switching to the Canvas Career learner experience/i,
    )
    fireEvent.click(checkbox)
    expect(mockSetTermsAccepted).toHaveBeenCalledWith(true)
  })

  it('disables the submit button when terms are not accepted', () => {
    setup()
    const submitButton = screen.getByText('Switch to Canvas Career').closest('button')
    expect(submitButton).toBeDisabled()
  })

  it('enables the submit button when terms are accepted', () => {
    setup({}, {isTermsAccepted: true})
    const submitButton = screen.getByText('Switch to Canvas Career').closest('button')
    expect(submitButton).not.toBeDisabled()
  })

  it('calls onSubmit when the submit button is clicked', () => {
    setup({}, {isTermsAccepted: true})
    const submitButton = screen.getByText('Switch to Canvas Career').closest('button')
    fireEvent.click(submitButton!)
    expect(mockOnSubmit).toHaveBeenCalledTimes(1)
  })

  it('disables the submit button when loading', () => {
    setup({}, {loadingText: 'Loading...', isTermsAccepted: true})
    const submitButton = screen.getByText('Switch to Canvas Career').closest('button')
    expect(submitButton).toBeDisabled()
  })
})
