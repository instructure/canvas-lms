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
import {render, screen, fireEvent} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import FilePreviewTray from '../FilePreviewTray'
import {type File} from '../../../../interfaces/File'

describe('FilePreviewTray', () => {
  const mockDismiss = jest.fn()

  const mockFileProps = {
    id: '1',
    uuid: 'uuid-1',
    folder_id: 'folder-1',
    display_name: 'Test File',
    filename: 'test-file.txt',
    upload_status: 'uploaded',
    'content-type': 'text/plain',
    url: 'http://example.com/test-file.txt',
    size: 1234,
    created_at: '2025-01-01T00:00:00Z',
    updated_at: '2025-01-01T00:00:00Z',
    unlock_at: null,
    locked: true,
    hidden: false,
    lock_at: null,
    hidden_for_user: false,
    thumbnail_url: null,
    modified_at: '2025-01-01T00:00:00Z',
    mime_class: 'text',
    media_entry_id: null,
    category: 'document',
    locked_for_user: false,
    visibility_level: 'public',
    usage_rights: null,
    preview_url: 'http://example.com/preview/test-file.txt',
    context_asset_string: 'context-1',
  }

  const renderComponent = (item: File) => {
    render(<FilePreviewTray onDismiss={mockDismiss} item={item} />)
  }

  test('renders FilePreviewTray component', () => {
    renderComponent(mockFileProps)
    const element = screen.getByText('File Info')
    expect(element).toBeInTheDocument()
  })

  test('calls onDismiss when close button is clicked', () => {
    renderComponent(mockFileProps)
    const closeButtonSpan = screen.getByTestId('tray-close-button')
    const closeButton = closeButtonSpan.querySelector('button') as HTMLButtonElement // InstUI CloseButton is a span with a button inside
    expect(closeButton).toBeInTheDocument()
    fireEvent.click(closeButton)
    expect(mockDismiss).toHaveBeenCalled()
  })

  test('displays the correct name for a file', () => {
    renderComponent(mockFileProps)
    expect(screen.getByText('Test File')).toBeInTheDocument()
  })

  test('displays the correct status text for published item', () => {
    const publishedProps = {...mockFileProps, locked: false}
    renderComponent(publishedProps)
    expect(screen.getByText('Published')).toBeInTheDocument()
  })
})
