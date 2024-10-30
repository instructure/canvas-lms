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
import FileFolderTable from '../FileFolderTable'

describe('FileFolderTable', () => {
  const columnVisibility = {
    small: ['Name'],
    medium: ['Name', 'Created', 'Last Modified', 'Rights', 'Published'],
    large: ['Name', 'Created', 'Last Modified', 'Modified By', 'Size', 'Rights', 'Published'],
  }

  it('renders all columns in large view', () => {
    render(<FileFolderTable size="large" />)

    const columns = columnVisibility.large
    columns.forEach(column => {
      expect(screen.getByText(column)).toBeInTheDocument()
    })
    expect(screen.getByTestId('actions')).toBeInTheDocument()
  })

  it('renders partial columns in medium view', () => {
    render(<FileFolderTable size="medium" />)

    const columns = columnVisibility.medium
    columns.forEach(column => {
      expect(screen.getByText(column)).toBeInTheDocument()
    })
    expect(screen.getByTestId('actions')).toBeInTheDocument()

    const hiddenColumns = columnVisibility.large.filter(column => !columns.includes(column))
    hiddenColumns.forEach(column => {
      expect(screen.queryByText(column)).not.toBeInTheDocument()
    })
  })

  it('renders partial columns in small view', () => {
    render(<FileFolderTable size="small" />)

    const columns = columnVisibility.small
    columns.forEach(column => {
      expect(screen.getByText(column)).toBeInTheDocument()
    })
    expect(screen.getByTestId('actions')).toBeInTheDocument()

    const hiddenColumns = columnVisibility.large.filter(column => !columns.includes(column))
    hiddenColumns.forEach(column => {
      expect(screen.queryByText(column)).not.toBeInTheDocument()
    })
  })

  it('renders filedrop when empty', () => {
    render(<FileFolderTable size="small" />)

    expect(screen.getByText('Drag a file here, or')).toBeInTheDocument()
  })
})
