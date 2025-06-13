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

import React from 'react'
import {render} from '@testing-library/react'

import FileFolderTable, {type FileFolderTableProps} from '..'
import {BrowserRouter} from 'react-router-dom'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'
import {FileManagementProvider} from '../../../contexts/FileManagementContext'
import {RowFocusProvider} from '../../../contexts/RowFocusContext'
import {RowsProvider} from '../../../contexts/RowsContext'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'
export const defaultProps: FileFolderTableProps = {
  size: 'large',
  rows: [],
  isLoading: false,
  userCanEditFilesForContext: true,
  userCanDeleteFilesForContext: true,
  userCanRestrictFilesForContext: true,
  usageRightsRequiredForContext: false,
  onSortChange: jest.fn(),
  sort: {
    by: 'name',
    direction: 'asc',
  },
  searchString: '',
  selectedRows: new Set<string>(),
  setSelectedRows: jest.fn(),
}

export const mockRowFocusContext = {
  setRowToFocus: jest.fn(),
  handleActionButtonRef: jest.fn(),
}

export const renderComponent = (props?: Partial<FileFolderTableProps>) => {
  const queryClient = new QueryClient()
  return render(
    <BrowserRouter>
      <MockedQueryClientProvider client={queryClient}>
        <FileManagementProvider value={createMockFileManagementContext()}>
          <RowFocusProvider value={mockRowFocusContext}>
            <RowsProvider value={{currentRows: props?.rows ?? [], setCurrentRows: jest.fn()}}>
              <FileFolderTable {...defaultProps} {...props} />
            </RowsProvider>
          </RowFocusProvider>
        </FileManagementProvider>
      </MockedQueryClientProvider>
    </BrowserRouter>,
  )
}
