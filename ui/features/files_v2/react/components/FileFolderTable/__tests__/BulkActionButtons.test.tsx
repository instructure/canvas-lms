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
import {type File, type Folder} from '../../../../interfaces/File'

let defaultProps: any
describe('BulkActionButtons', () => {
  beforeEach(() => {
    defaultProps = {
      size: 'medium',
      selectedRows: new Set(['1', '2']),
      totalRows: 10,
      userCanEditFilesForContext: true,
      userCanDeleteFilesForContext: true,
      rows: [
        {id: '1', uuid: '1', display_name: 'File 1'} as File,
        {id: '2', uuid: '2', display_name: 'File 2'} as File,
      ],
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

  it('renders the delete button as disabled when no rows are selected', () => {
    defaultProps.selectedRows = new Set()
    render(<BulkActionButtons {...defaultProps} />)
    const deleteButton = screen.getByTestId('bulk-actions-delete-button')
    expect(deleteButton.closest('button')).toHaveAttribute('disabled')
  })

  it('renders the delete button as enabled when rows are selected', () => {
    render(<BulkActionButtons {...defaultProps} />)
    const deleteButton = screen.getByTestId('bulk-actions-delete-button')
    expect(deleteButton.closest('button')).not.toHaveAttribute('disabled')
  })

  it('opens the delete modal with selected rows when delete button is clicked', async () => {
    render(<BulkActionButtons {...defaultProps} />)
    const deleteButton = screen.getByTestId('bulk-actions-delete-button')
    fireEvent.click(deleteButton)
    expect(await screen.findByText('Delete Items')).toBeInTheDocument()
  })

  it('renders the more button as disabled when no rows are selected', () => {
    defaultProps.selectedRows = new Set()
    render(<BulkActionButtons {...defaultProps} />)
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    expect(moreButton.closest('button')).toHaveAttribute('disabled')
  })

  it('renders the more button as enabled when rows are selected', () => {
    render(<BulkActionButtons {...defaultProps} />)
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    expect(moreButton.closest('button')).not.toHaveAttribute('disabled')
  })

  it('renders the manage access button when userCanEditFilesForContext is true', async () => {
    render(<BulkActionButtons {...defaultProps} />)
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)
    await waitFor(() => {
      expect(screen.getByTestId('bulk-actions-manage-usage-rights-button')).toBeInTheDocument()
    })
  })

  it('does not render the manage access button when userCanEditFilesForContext is false', async () => {
    defaultProps.userCanEditFilesForContext = false
    render(<BulkActionButtons {...defaultProps} />)
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)
    await waitFor(() => {
      expect(screen.queryByTestId('bulk-actions-manage-usage-rights-button')).toBeNull()
    })
  })

  it('renders the move button when userCanEditFilesForContext is true', async () => {
    render(<BulkActionButtons {...defaultProps} />)
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)
    await waitFor(() => {
      expect(screen.getByTestId('bulk-actions-move-button')).toBeInTheDocument()
    })
  })

  it('does not render the move button when userCanEditFilesForContext is false', async () => {
    defaultProps.userCanEditFilesForContext = false
    render(<BulkActionButtons {...defaultProps} />)
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)
    await waitFor(() => {
      expect(screen.queryByTestId('bulk-actions-move-button')).toBeNull()
    })
  })
})


