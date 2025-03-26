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
import FilePreviewModal from '../FilePreviewModal'
import NoFilePreviewAvailable from '../NoFilePreviewAvailable'
import StudioMediaPlayer from '@canvas/canvas-studio-player'

jest.mock('../NoFilePreviewAvailable', () =>
  jest.fn(() => <div data-testid="no-preview">No preview available</div>),
)
jest.mock('@canvas/canvas-studio-player', () =>
  jest.fn(() => <div data-testid="media-player">Media Player</div>),
)
import {FAKE_FILES} from '../../../../fixtures/fakeData'

describe('FilePreviewModal', () => {
  const mockProps = {
    isOpen: true,
    onClose: jest.fn(),
    item: FAKE_FILES[0],
    collection: FAKE_FILES,
  }

  beforeEach(() => {
    jest.clearAllMocks()
    window.history.replaceState = jest.fn()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('renders the modal when open', () => {
    render(<FilePreviewModal {...mockProps} />)
    expect(screen.queryAllByText('example.pdf')).toBeTruthy()
  })

  it('calls onClose when close button is clicked', () => {
    render(<FilePreviewModal {...mockProps} />)
    fireEvent.click(screen.getByTestId('close-button'))
    expect(mockProps.onClose).toHaveBeenCalledTimes(2)
  })

  it('does not render the modal when closed', () => {
    render(<FilePreviewModal {...mockProps} isOpen={false} />)
    expect(screen.queryByText('example.pdf')).not.toBeInTheDocument()
  })

  it('renders StudioMediaPlayer when file is a media type', () => {
    const mediaProps = {
      ...mockProps,
      item: {...mockProps.item, mime_class: 'video', media_entry_id: 'media-123'},
    }
    render(<FilePreviewModal {...mediaProps} />)
    expect(screen.getByTestId('media-player')).toBeInTheDocument()
    expect(StudioMediaPlayer).toHaveBeenCalledWith(
      expect.objectContaining({media_id: 'media-123'}),
      {},
    )
  })

  it('renders NoFilePreviewAvailable for unsupported file types', () => {
    const unsupportedProps = {...mockProps, item: {...mockProps.item, mime_class: 'unsupported'}}
    render(<FilePreviewModal {...unsupportedProps} />)
    expect(screen.getByTestId('no-preview')).toBeInTheDocument()
    expect(NoFilePreviewAvailable).toHaveBeenCalledWith(
      expect.objectContaining({item: unsupportedProps.item}),
      {},
    )
  })

  it('renders the next and previous buttons if collection has more than one item', () => {
    render(<FilePreviewModal {...mockProps} />)
    expect(screen.getByTestId('next-button')).toBeInTheDocument()
    expect(screen.getByTestId('previous-button')).toBeInTheDocument()
  })

  it('does not render the next and previous buttons if collection has one item', () => {
    render(<FilePreviewModal {...mockProps} collection={[FAKE_FILES[0]]} />)
    expect(screen.queryByTestId('next-button')).not.toBeInTheDocument()
    expect(screen.queryByTestId('previous-button')).not.toBeInTheDocument()
  })

  it('navigates to next file when next button is clicked', async () => {
    render(<FilePreviewModal {...mockProps} />)
    fireEvent.click(screen.getByTestId('next-button'))
    const header = await screen.findByTestId('file-header')
    expect(header.textContent).toBe(FAKE_FILES[1].display_name)
    expect(window.history.replaceState).toHaveBeenCalled()
  })

  it('navigates to previous file when previous button is clicked', async () => {
    render(<FilePreviewModal {...mockProps} />)
    fireEvent.click(screen.getByTestId('previous-button'))
    const header = await screen.findByTestId('file-header')
    expect(header.textContent).toBe(FAKE_FILES[FAKE_FILES.length - 1].display_name)
    expect(window.history.replaceState).toHaveBeenCalled()
  })
})
