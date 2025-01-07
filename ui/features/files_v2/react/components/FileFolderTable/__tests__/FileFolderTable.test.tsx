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
import FileFolderTable from '..'
import {BrowserRouter} from 'react-router-dom'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'
import fetchMock from 'fetch-mock'
import {FAKE_FILES, FAKE_FOLDERS, FAKE_FOLDERS_AND_FILES} from '../../../../fixtures/fakeData'
import {FileManagementContext} from '../../Contexts'

const defaultProps = {
  size: 'large' as 'large' | 'small' | 'medium',
  userCanEditFilesForContext: true,
}

const renderComponent = (props = {}) => {
  const queryClient = new QueryClient()

  return render(
    <BrowserRouter>
      <MockedQueryClientProvider client={queryClient}>
        <FileManagementContext.Provider
          value={{contextType: 'course', contextId: '1', folderId: '1'}}
        >
          <FileFolderTable {...defaultProps} {...props} />
        </FileManagementContext.Provider>
      </MockedQueryClientProvider>
    </BrowserRouter>,
  )
}

describe('FileFolderTable', () => {
  beforeEach(() => {
    fetchMock.get(/.*\/folders/, FAKE_FOLDERS_AND_FILES)
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders filedrop when no results and not loading', async () => {
    fetchMock.get(/.*\/folders/, [], {overwriteRoutes: true})
    renderComponent()

    expect(await screen.findByText('Drag a file here, or')).toBeInTheDocument()
  })

  it('renders spinner and no filedrop when loading', () => {
    fetchMock.get(/.*\/folders/, FAKE_FOLDERS_AND_FILES, {overwriteRoutes: true, delay: 5000})
    renderComponent()

    expect(screen.getByText('Loading data')).toBeInTheDocument()
    expect(screen.queryByText('Drag a file here, or')).not.toBeInTheDocument()
  })

  it('renders stacked when not large', async () => {
    renderComponent({size: 'medium'})

    expect(await screen.findAllByTestId('row-select-checkbox')).toHaveLength(
      FAKE_FOLDERS_AND_FILES.length,
    )
  })

  it('renders file/folder rows when results', async () => {
    renderComponent()

    expect(await screen.findAllByTestId('table-row')).toHaveLength(FAKE_FOLDERS_AND_FILES.length)
    expect(screen.getByText(FAKE_FOLDERS_AND_FILES[0].name)).toBeInTheDocument()
  })

  describe('FileFolderTable - modifiedBy column', () => {
    it('renders link with user profile of file rows when modified by user', async () => {
      fetchMock.get(/.*\/folders/, [FAKE_FILES[0]], {overwriteRoutes: true})
      const {display_name, html_url} = FAKE_FILES[0].user || {}

      expect(display_name).toBeDefined()
      renderComponent()
      const userLink = await screen.findByText(display_name!)
      expect(userLink).toBeInTheDocument()
      expect(userLink.closest('a')).toHaveAttribute('href', html_url!)
    })

    it('does not render link when folder', () => {
      fetchMock.get(/.*\/folders/, [FAKE_FOLDERS[0]], {overwriteRoutes: true})
      renderComponent()

      const userLinks = screen.queryAllByText((_, element) => {
        if (!element) return false
        return !!element.closest('a')?.getAttribute('href')?.includes('/users/')
      })
      expect(userLinks).toHaveLength(0)
    })
  })

  describe('FileFolderTable - selection behavior', () => {
    it('allows row selection and highlights selected rows', async () => {
      fetchMock.get(/.*\/folders/, [FAKE_FILES[0]], {overwriteRoutes: true, delay: 0})
      renderComponent()

      const rowCheckboxes = await screen.findAllByTestId('row-select-checkbox')
      // Select first row
      fireEvent.click(rowCheckboxes[0])

      const firstRow = screen.getAllByTestId('table-row')[0]
      expect(firstRow).toHaveStyle({borderColor: 'brand'})
    })

    it('allows "Select All" functionality', async () => {
      fetchMock.get(/.*\/folders/, [FAKE_FILES[0], FAKE_FILES[1]], {
        overwriteRoutes: true,
        delay: 0,
      })
      renderComponent()

      const selectAllCheckbox = await screen.findByTestId('select-all-checkbox')
      const rowCheckboxes = await screen.findAllByTestId('row-select-checkbox')

      // Select all rows
      fireEvent.click(selectAllCheckbox)
      rowCheckboxes.forEach(checkbox => expect(checkbox).toBeChecked())

      // Unselect all rows
      fireEvent.click(selectAllCheckbox)
      rowCheckboxes.forEach(checkbox => expect(checkbox).not.toBeChecked())
    })

    it('sets "Select All" checkbox to indeterminate when some rows are selected', async () => {
      fetchMock.get(/.*\/folders/, [FAKE_FILES[0], FAKE_FILES[1]], {
        overwriteRoutes: true,
        delay: 0,
      })
      renderComponent()

      const selectAllCheckbox = await screen.findByTestId('select-all-checkbox')
      const rowCheckboxes = await screen.findAllByTestId('row-select-checkbox')

      // Select the first row only
      fireEvent.click(rowCheckboxes[0])

      await waitFor(() => {
        expect(selectAllCheckbox).toBeDefined()
        expect((selectAllCheckbox as HTMLInputElement).indeterminate).toBe(true)
      })
    })

    it('updates "Select All" checkbox correctly when all rows are selected', async () => {
      fetchMock.get(/.*\/folders/, [FAKE_FILES[0], FAKE_FILES[1]], {
        overwriteRoutes: true,
        delay: 0,
      })
      renderComponent()

      const selectAllCheckbox = await screen.findByTestId('select-all-checkbox')
      const rowCheckboxes = await screen.findAllByTestId('row-select-checkbox')

      expect(selectAllCheckbox).toBeDefined()
      // Select all rows
      fireEvent.click(selectAllCheckbox)
      expect(selectAllCheckbox).toBeChecked()

      // Unselect one row
      fireEvent.click(rowCheckboxes[0])
      await waitFor(() => {
        expect(selectAllCheckbox).not.toBeChecked()
        expect((selectAllCheckbox as HTMLInputElement).indeterminate).toBe(true)
      })
    })
  })
})
