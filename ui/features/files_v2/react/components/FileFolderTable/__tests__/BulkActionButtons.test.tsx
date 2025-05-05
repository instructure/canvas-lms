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
import {FileManagementProvider} from '../../../contexts/FileManagementContext'
import {RowFocusProvider} from '../../../contexts/RowFocusContext'
import {RowsProvider} from '../../../contexts/RowsContext'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'
import {mockRowFocusContext} from './testUtils'
import BulkActionButtons, {BulkActionButtonsProps} from '../BulkActionButtons'
import {type File, Folder} from '../../../../interfaces/File'

const defaultProps: BulkActionButtonsProps = {
  size: 'medium',
  selectedRows: new Set(['file-1', 'file-2']),
  totalRows: 10,
  userCanEditFilesForContext: true,
  userCanDeleteFilesForContext: true,
  userCanRestrictFilesForContext: true,
  usageRightsRequiredForContext: true,
  rows: [{id: 1, display_name: 'File 1'} as File, {id: 2, display_name: 'File 2'} as File],
}

const renderComponent = (props: BulkActionButtonsProps = {...defaultProps}) => {
  return render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <RowFocusProvider value={mockRowFocusContext}>
        <RowsProvider value={{setCurrentRows: jest.fn(), currentRows: props.rows}}>
          <BulkActionButtons {...defaultProps} {...props} />
        </RowsProvider>
      </RowFocusProvider>
    </FileManagementProvider>,
  )
}

describe('BulkActionButtons', () => {
  it('renders component with all options enabled', async () => {
    renderComponent()
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
    renderComponent({...defaultProps, userCanDeleteFilesForContext: false})
    expect(screen.queryByTestId('bulk-actions-delete-button')).toBeNull()
  })

  it('does not render permissions button when userCanRestrictFilesForContext is false', async () => {
    renderComponent({
      ...defaultProps,
      userCanEditFilesForContext: true,
      userCanRestrictFilesForContext: false,
    })
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)
    await waitFor(() => {
      expect(screen.queryByTestId('bulk-actions-edit-permissions-button')).toBeNull()
    })
  })

  it('does not render more actions when userCanEditFilesForContext is false', async () => {
    renderComponent({
      ...defaultProps,
      userCanEditFilesForContext: false,
      userCanRestrictFilesForContext: false,
    })
    expect(screen.queryByTestId('bulk-actions-more-button')).toBeNull()
  })

  it('does not render manage access when usageRightsRequiredForContext is false', async () => {
    renderComponent({...defaultProps, usageRightsRequiredForContext: false})
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)
    await waitFor(() => {
      expect(screen.queryByTestId('bulk-actions-manage-usage-rights-button')).toBeNull()
    })
  })

  it('renders disabled buttons when no selection', async () => {
    renderComponent({...defaultProps, selectedRows: new Set()})
    expect(screen.getByText('0 selected')).toBeInTheDocument()

    const button = screen.getByTestId('bulk-actions-more-button')
    expect(button.closest('button')).toHaveAttribute('disabled')
  })

  it('renders the delete button as disabled when no rows are selected', () => {
    renderComponent({...defaultProps, selectedRows: new Set()})
    const deleteButton = screen.getByTestId('bulk-actions-delete-button')
    expect(deleteButton.closest('button')).toHaveAttribute('disabled')
  })

  it('renders the delete button as enabled when rows are selected', () => {
    renderComponent()
    const deleteButton = screen.getByTestId('bulk-actions-delete-button')
    expect(deleteButton.closest('button')).not.toHaveAttribute('disabled')
  })

  it('opens the delete modal with selected rows when delete button is clicked', async () => {
    renderComponent()
    const deleteButton = screen.getByTestId('bulk-actions-delete-button')
    fireEvent.click(deleteButton)
    expect(await screen.findByText('Delete Items')).toBeInTheDocument()
  })

  it('renders the more button as disabled when no rows are selected', () => {
    renderComponent({...defaultProps, selectedRows: new Set()})
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    expect(moreButton.closest('button')).toHaveAttribute('disabled')
  })

  it('renders the more button as enabled when rows are selected', () => {
    renderComponent()
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    expect(moreButton.closest('button')).not.toHaveAttribute('disabled')
  })

  it('renders the manage access button when userCanEditFilesForContext is true', async () => {
    renderComponent()
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)
    await waitFor(() => {
      expect(screen.getByTestId('bulk-actions-manage-usage-rights-button')).toBeInTheDocument()
    })
  })

  it('renders the move button when userCanEditFilesForContext is true', async () => {
    renderComponent()
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)
    await waitFor(() => {
      expect(screen.getByTestId('bulk-actions-move-button')).toBeInTheDocument()
    })
  })

  it('disables Delete, Manage Usage Rights, Edit Permissions, and Move To when a locked BP is selected', async () => {
    renderComponent({
      ...defaultProps,
      rows: [
        {id: 1, display_name: 'File 1', restricted_by_master_course: true} as File,
        {id: 2, display_name: 'File 2'} as File,
      ],
    })
    const moreButton = screen.getByTestId('bulk-actions-more-button')
    fireEvent.click(moreButton)
    await waitFor(() => {
      expect(screen.queryByTestId('bulk-actions-delete-button')).toHaveAttribute('disabled')
      expect(screen.queryByTestId('bulk-actions-manage-usage-rights-button')).toHaveAttribute(
        'aria-disabled',
        'true',
      )
      expect(screen.queryByTestId('bulk-actions-edit-permissions-button')).toHaveAttribute(
        'aria-disabled',
        'true',
      )
      expect(screen.queryByTestId('bulk-actions-move-button')).toHaveAttribute(
        'aria-disabled',
        'true',
      )
    })
  })

  describe('Folders', () => {
    beforeEach(() => {
      renderComponent({
        ...defaultProps,
        rows: [{id: 1, name: 'Folder 1'} as Folder, {id: 2, name: 'Folder 2'} as Folder],
        selectedRows: new Set(['folder-1', 'folder-2']),
      })
    })

    it('renders the manage access button for folders', async () => {
      const moreButton = screen.getByTestId('bulk-actions-more-button')
      fireEvent.click(moreButton)
      await waitFor(() => {
        expect(screen.getByTestId('bulk-actions-manage-usage-rights-button')).toBeInTheDocument()
      })
    })
  })
})
