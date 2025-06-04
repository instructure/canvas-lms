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
import {render, screen} from '@testing-library/react'
import CommonFileInfo from '../CommonFileInfo'
import type {File} from '../../../../../interfaces/File'
import {
  getRestrictedText,
  isHidden,
  isPublished,
  isRestricted,
} from '../../../../../utils/fileUtils'

jest.mock('../../../../../utils/fileUtils', () => ({
  getRestrictedText: jest.fn(() => 'Restricted Text'),
  isHidden: jest.fn(() => false),
  isPublished: jest.fn(() => true),
  isRestricted: jest.fn(() => false),
}))

describe('CommonFileInfo', () => {
  const mockItem = {
    display_name: 'Sample File',
    locked: true,
    usage_rights: {license_name: 'Creative Commons'},
    'content-type': 'application/pdf',
    size: 1024,
    created_at: '2025-03-04T12:00:00Z',
    updated_at: '2025-03-05T14:30:00Z',
  }

  it('renders file information correctly', () => {
    // Mock the file utils to return expected values
    ;(isPublished as jest.Mock).mockReturnValue(true)
    ;(isRestricted as jest.Mock).mockReturnValue(true)
    ;(isHidden as jest.Mock).mockReturnValue(false)
    ;(getRestrictedText as jest.Mock).mockReturnValue('Restricted File')

    render(<CommonFileInfo item={mockItem as File} />)
    expect(screen.getByText('File Info')).toBeInTheDocument()
    expect(screen.getByText('Name')).toBeInTheDocument()
    expect(screen.getByTestId('file-display-name')).toBeInTheDocument()
    expect(screen.getByText('Status')).toBeInTheDocument()
    expect(screen.getByText('Restricted File')).toBeInTheDocument()
    expect(screen.getByText('License')).toBeInTheDocument()
    expect(screen.getByText('Creative Commons')).toBeInTheDocument()
    expect(screen.getByText('Type')).toBeInTheDocument()
    expect(screen.getByText('application/pdf')).toBeInTheDocument()
    expect(screen.getByText('Size')).toBeInTheDocument()
    expect(screen.getByText('1 KB')).toBeInTheDocument()
  })

  it('renders formatted creation and modification dates', () => {
    render(<CommonFileInfo item={mockItem as File} />)

    expect(screen.getByText('Date Created')).toBeInTheDocument()
    expect(screen.getByText(new Date(mockItem.created_at).toLocaleString())).toBeInTheDocument()
    expect(screen.getByText('Date Modified')).toBeInTheDocument()
    expect(screen.getByText(new Date(mockItem.updated_at).toLocaleString())).toBeInTheDocument()
  })

  it('renders "Hidden" if file is published but hidden', () => {
    ;(isRestricted as jest.Mock).mockReturnValue(false)
    ;(isHidden as jest.Mock).mockReturnValue(true)
    render(<CommonFileInfo item={mockItem as File} />)
    expect(screen.getByText('Hidden')).toBeInTheDocument()
  })

  it('renders "Restricted Text" if file is published and restricted', () => {
    ;(isRestricted as jest.Mock).mockReturnValue(true)
    ;(getRestrictedText as jest.Mock).mockReturnValue('Restricted Text')
    render(<CommonFileInfo item={mockItem as File} />)
    expect(screen.getByText('Status')).toBeInTheDocument()
    expect(screen.getByText('Restricted Text')).toBeInTheDocument()
  })
})
