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
import {render, screen, waitFor} from '@testing-library/react'
import FileSelectBox from '../FileSelectBox'
import FileStore from '../../../stores/FileStore'
import FolderStore from '../../../stores/FolderStore'

jest.mock('../../../stores/FileStore')
jest.mock('../../../stores/FolderStore')

const folders = [
  {
    full_name: 'course files',
    id: 112,
    parent_folder_id: null,
  },
  {
    full_name: 'course files/A',
    id: 113,
    parent_folder_id: 112,
  },
  {
    full_name: 'course files/C',
    id: 114,
    parent_folder_id: 112,
  },
  {
    full_name: 'course files/B',
    id: 115,
    parent_folder_id: 112,
  },
  {
    full_name: 'course files/NoFiles',
    id: 116,
    parent_folder_id: 112,
  },
]

const files = [
  {
    id: 1,
    folder_id: 112,
    display_name: 'cf-1',
  },
  {
    id: 2,
    folder_id: 113,
    display_name: 'A-1',
  },
  {
    id: 3,
    folder_id: 114,
    display_name: 'C-1',
  },
  {
    id: 4,
    folder_id: 115,
    display_name: 'B-1',
  },
]

describe('FileSelectBox', () => {
  let fileStoreCallback
  let folderStoreCallback

  beforeEach(() => {
    let fileStoreState = {
      isLoading: true,
      items: [],
    }

    let folderStoreState = {
      isLoading: true,
      items: [],
    }

    FileStore.mockImplementation(() => ({
      getState: () => fileStoreState,
      addChangeListener: callback => {
        fileStoreCallback = () => {
          fileStoreState = {
            isLoading: false,
            items: files,
          }
          callback(fileStoreState)
        }
      },
      fetch: () => {
        setTimeout(() => {
          fileStoreCallback()
        }, 0)
      },
    }))

    FolderStore.mockImplementation(() => ({
      getState: () => folderStoreState,
      addChangeListener: callback => {
        folderStoreCallback = () => {
          folderStoreState = {
            isLoading: false,
            items: folders,
          }
          callback(folderStoreState)
        }
      },
      fetch: () => {
        setTimeout(() => {
          folderStoreCallback()
        }, 0)
      },
    }))
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the component', () => {
    render(<FileSelectBox contextString="test_3" />)
    const selectBox = screen.getByRole('listbox', {
      name: 'Select the files you want to associate, or add files by selecting "Create File(s)".',
    })
    expect(selectBox).toBeInTheDocument()
  })

  it('alphabetizes the folder list and excludes empty folders', async () => {
    render(<FileSelectBox contextString="test_3" />)

    const expectedFolders = ['course files', 'course files/A', 'course files/B', 'course files/C']

    // Wait for both store callbacks to complete
    await waitFor(
      () => {
        expect(screen.queryByText('Loading...')).not.toBeInTheDocument()
      },
      {timeout: 2000},
    )

    for (const folderName of expectedFolders) {
      expect(screen.getByRole('group', {name: folderName})).toBeInTheDocument()
    }

    const noFilesFolder = screen.queryByRole('group', {name: 'course files/NoFiles'})
    expect(noFilesFolder).not.toBeInTheDocument()
  })

  it('shows loading state while files are loading', async () => {
    render(<FileSelectBox contextString="test_3" />)

    const select = screen.getByRole('listbox')
    expect(select).toHaveAttribute('aria-busy', 'true')

    const loadingOption = screen.getByText('Loading...')
    expect(loadingOption).toBeInTheDocument()

    // Wait for both store callbacks to complete
    await waitFor(
      () => {
        expect(screen.queryByText('Loading...')).not.toBeInTheDocument()
      },
      {timeout: 2000},
    )

    expect(select).toHaveAttribute('aria-busy', 'false')
    expect(screen.getByRole('group', {name: 'course files'})).toBeInTheDocument()
  })

  it('renders Create Files button', () => {
    render(<FileSelectBox contextString="test_3" />)
    const createOption = screen.getByRole('option', {name: '[ Create File(s) ]'})
    expect(createOption).toBeInTheDocument()
  })
})
