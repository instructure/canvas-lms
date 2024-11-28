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
import FileFolderTable from '..'
import {FAKE_FILES, FAKE_FOLDERS, FAKE_FOLDERS_AND_FILES} from '../../../../data/FakeData'
import {BrowserRouter} from 'react-router-dom'

const defaultProps = {
  size: 'large' as 'large' | 'small' | 'medium',
  isLoading: false,
  rows: [],
  userCanEditFilesForContext: true,
}
const renderComponent = (props = {}) => {
  return render(
    <BrowserRouter>
      <FileFolderTable {...defaultProps} {...props} />
    </BrowserRouter>
  )
}

describe('FileFolderTable', () => {
  it('renders filedrop when no results and not loading', () => {
    renderComponent()

    expect(screen.getByText('Drag a file here, or')).toBeInTheDocument()
  })

  it('renders spinner and no filedrop when loading', () => {
    renderComponent({isLoading: true})

    expect(screen.getByText('Loading data')).toBeInTheDocument()
    expect(screen.queryByText('Drag a file here, or')).not.toBeInTheDocument()
  })

  it('renders stacked when not large', () => {
    renderComponent({size: 'medium', rows: FAKE_FOLDERS_AND_FILES})

    expect(screen.getAllByText('Name:')).toHaveLength(FAKE_FOLDERS_AND_FILES.length)
  })

  it('renders file/folder rows when results', () => {
    renderComponent({rows: FAKE_FOLDERS_AND_FILES})

    expect(screen.getAllByTestId('table-row')).toHaveLength(FAKE_FOLDERS_AND_FILES.length)
    expect(screen.getByText(FAKE_FOLDERS_AND_FILES[0].name)).toBeInTheDocument()
  })

  describe('FileFolderTable - modifiedBy column', () => {
    it('renders link with user profile of file rows when modified by user', () => {
      const { display_name, html_url } = FAKE_FILES[0].user || {}

      expect(display_name).toBeDefined()
      renderComponent({ rows: [FAKE_FILES[0]] })

      const userLink = screen.getByText(display_name!)
      expect(userLink).toBeInTheDocument()
      expect(userLink.closest('a')).toHaveAttribute('href', html_url!)
    })

    it('does not render link when folder', () => {
      renderComponent({ rows: [FAKE_FOLDERS[0]] })

      const userLinks = screen.queryAllByText((_, element) => {
        if (!element) return false
        return !!element.closest('a')?.getAttribute('href')?.includes('/users/')
      })
      expect(userLinks.length).toBe(0)
    })
  })
})
