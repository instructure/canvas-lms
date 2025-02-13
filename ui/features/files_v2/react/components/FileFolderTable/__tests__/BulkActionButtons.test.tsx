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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import BulkActionButtons from '../BulkActionButtons'

let defaultProps: any
describe('BulkActionButtons', () => {
  beforeEach(() => {
    defaultProps = {
      selectedRows: new Set(['1', '2']),
      totalRows: 10,
      userCanEditFilesForContext: true,
      userCanDeleteFilesForContext: true,
    }
  })

  it('renders component with all options enabled', async () => {
    render(<BulkActionButtons {...defaultProps} />)
    expect(screen.getByText('2 of 10 selected')).toBeInTheDocument()
    expect(screen.getByTestId('bulk-actions-delete-button')).toBeInTheDocument()

    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)

    await waitFor(() => {
      expect(screen.getByTestId('bulk-actions-manage-usage-rights-button')).toBeInTheDocument()
      expect(screen.getByTestId('bulk-actions-edit-permissions-button')).toBeInTheDocument()
      expect(screen.getByTestId('bulk-actions-move-button')).toBeInTheDocument()
    })
  })

  it('does not render delete button when userCanDeleteFilesForContext is false', () => {
    defaultProps.userCanDeleteFilesForContext = false
    render(<BulkActionButtons {...defaultProps} />)
    expect(screen.queryByTestId('bulk-actions-delete-button')).toBeNull()
  })

  it('does not render manage access and move to when userCanEditFilesForContext is false', async () => {
    defaultProps.userCanEditFilesForContext = false
    render(<BulkActionButtons {...defaultProps} />)

    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)

    await waitFor(() => {
      expect(screen.queryByTestId('bulk-actions-manage-usage-rights-button')).toBeNull()
      expect(screen.queryByTestId('bulk-actions-edit-permissions-button')).toBeNull()
      expect(screen.queryByTestId('bulk-actions-move-button')).toBeNull()
    })
  })

  it('renders disabled buttons when no selection', async () => {
    defaultProps.selectedRows = new Set()
    render(<BulkActionButtons {...defaultProps} />)
    expect(screen.getByText('0 selected')).toBeInTheDocument()

    const button = screen.getByTestId('bulk-actions-more-button')
    expect(button.closest('button')).toHaveAttribute('disabled')
  })
})
