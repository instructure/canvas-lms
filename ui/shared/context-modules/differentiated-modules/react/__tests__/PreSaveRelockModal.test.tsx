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
import userEvent from '@testing-library/user-event'
import PreSaveRelockModal from '../PreSaveRelockModal'

describe('PreSaveRelockModal', () => {
  const mockOnSave = vi.fn()
  const mockOnCancel = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  const defaultProps = {
    open: true,
    onSave: mockOnSave,
    onCancel: mockOnCancel,
  }

  it('calls onCancel when Cancel button is clicked', async () => {
    const user = userEvent.setup()
    render(<PreSaveRelockModal {...defaultProps} />)

    const cancelButton = screen.getByTestId('relock-cancel-button')
    await user.click(cancelButton)

    expect(mockOnCancel).toHaveBeenCalledTimes(1)
    expect(mockOnSave).not.toHaveBeenCalled()
  })

  it('calls onSave with true when Re-Lock Modules button is clicked', async () => {
    const user = userEvent.setup()
    mockOnSave.mockResolvedValue(undefined)
    render(<PreSaveRelockModal {...defaultProps} />)

    const relockButton = screen.getByTestId('relock-button')
    await user.click(relockButton)

    expect(mockOnSave).toHaveBeenCalledWith(true)
    expect(mockOnCancel).not.toHaveBeenCalled()
  })

  it('calls onSave with false when Continue button is clicked', async () => {
    const user = userEvent.setup()
    mockOnSave.mockResolvedValue(undefined)
    render(<PreSaveRelockModal {...defaultProps} />)

    const continueButton = screen.getByTestId('continue-without-relock-button')
    await user.click(continueButton)

    expect(mockOnSave).toHaveBeenCalledWith(false)
    expect(mockOnCancel).not.toHaveBeenCalled()
  })
})
