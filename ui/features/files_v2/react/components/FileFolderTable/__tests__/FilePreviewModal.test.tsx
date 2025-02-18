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
import { render, screen, fireEvent } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import FilePreviewModal from '../FilePreviewModal'
import NoFilePreviewAvailable from '../NoFilePreviewAvailable';
import StudioMediaPlayer from '@canvas/canvas-studio-player';

jest.mock('../NoFilePreviewAvailable', () => jest.fn(() => <div data-testid="no-preview">No preview available</div>));
jest.mock('@canvas/canvas-studio-player', () => jest.fn(() => <div data-testid="media-player">Media Player</div>));

describe('FilePreviewModal', () => {
const mockProps = {
  isOpen: true,
  onClose: jest.fn(),
  item: {
    id: '1',
    uuid: 'uuid-1',
    folder_id: 'folder-1',
    display_name: 'example.pdf',
    filename: 'example.pdf',
    upload_status: 'uploaded',
    'content-type': 'application/pdf',
    url: 'http://example.com/example.pdf',
    size: 1024,
    created_at: '2025-01-01T00:00:00Z',
    updated_at: '2025-01-01T00:00:00Z',
    unlock_at: null,
    locked: false,
    hidden: false,
    lock_at: null,
    hidden_for_user: false,
    thumbnail_url: null,
    modified_at: '2025-01-01T00:00:00Z',
    mime_class: 'pdf',
    media_entry_id: null,
    category: 'document',
    locked_for_user: false,
    visibility_level: 'public',
    preview_url: 'http://example.com/preview/example.pdf',
    context_asset_string: 'context-1',
  },
}

  it('renders the modal when open', () => {
    render(<FilePreviewModal {...mockProps} />)
    expect(screen.queryAllByText('example.pdf')).toBeTruthy()
  })

  it('calls onClose when close button is clicked', () => {
    render(<FilePreviewModal {...mockProps} />)
    fireEvent.click(screen.getByTestId('close-button'))
    expect(mockProps.onClose).toHaveBeenCalledTimes(1)
  })

  it('does not render the modal when closed', () => {
    render(<FilePreviewModal {...mockProps} isOpen={false} />)
    expect(screen.queryByText('example.pdf')).not.toBeInTheDocument()
  })

  it('renders StudioMediaPlayer when file is a media type', () => {
    const mediaProps = { ...mockProps, item: { ...mockProps.item, mime_class: 'video', media_entry_id: 'media-123' } };
    render(<FilePreviewModal {...mediaProps} />);
    expect(screen.getByTestId('media-player')).toBeInTheDocument();
    expect(StudioMediaPlayer).toHaveBeenCalledWith(expect.objectContaining({ media_id: 'media-123' }), {});
  })

  it('renders NoFilePreviewAvailable for unsupported file types', () => {
    const unsupportedProps = { ...mockProps, item: { ...mockProps.item, mime_class: 'unsupported' } };
    render(<FilePreviewModal {...unsupportedProps} />);
    expect(screen.getByTestId('no-preview')).toBeInTheDocument();
    expect(NoFilePreviewAvailable).toHaveBeenCalledWith(expect.objectContaining({ item: unsupportedProps.item }), {});
  })
})
