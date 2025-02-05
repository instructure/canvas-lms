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
import {FileManagementContext} from '../../Contexts'

export const defaultProps: FileFolderTableProps = {
  size: 'large',
  userCanEditFilesForContext: true,
  userCanDeleteFilesForContext: true,
  usageRightsRequiredForContext: false,
  currentUrl:
    '/api/v1/folders/1/all?include[]=user&include[]=usage_rights&include[]=enhanced_preview_url&include[]=context_asset_string',
  folderBreadcrumbs: [],
  onPaginationLinkChange: jest.fn(),
  onLoadingStatusChange: jest.fn(),
  onSortChange: jest.fn(),
  searchString: '',
}

export const renderComponent = (props = {}) => {
  const queryClient = new QueryClient()
  return render(
    <BrowserRouter>
      <MockedQueryClientProvider client={queryClient}>
        <FileManagementContext.Provider
          value={{contextType: 'course', contextId: '1', folderId: '1', showingAllContexts: false}}
        >
          <FileFolderTable {...defaultProps} {...props} />
        </FileManagementContext.Provider>
      </MockedQueryClientProvider>
    </BrowserRouter>,
  )
}
