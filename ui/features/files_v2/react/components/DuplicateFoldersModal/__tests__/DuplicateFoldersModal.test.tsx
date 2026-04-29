/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {render, screen, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {DuplicateFoldersModal} from '../DuplicateFoldersModal'
import type {Folder} from '../../../../interfaces/File'

const mockFolder1: Folder = {
  id: '1',
  name: 'Folder',
  full_name: 'course files / Folder',
  context_id: '123',
  context_type: 'Course',
  parent_folder_id: '0',
  created_at: '2026-02-10T14:27:27Z',
  updated_at: '2026-02-10T14:27:27Z',
  lock_at: null,
  unlock_at: null,
  position: 1,
  locked: false,
  folders_url: '',
  files_url: '',
  files_count: 0,
  folders_count: 0,
  hidden: false,
  locked_for_user: false,
  hidden_for_user: false,
  for_submissions: false,
  can_upload: true,
}

const mockFolder2: Folder = {
  ...mockFolder1,
  id: '2',
  created_at: '2026-02-10T14:28:00Z',
}

const mockFolder3: Folder = {
  ...mockFolder1,
  id: '3',
  created_at: '2026-02-10T14:29:00Z',
}

describe('DuplicateFoldersModal', () => {
  const defaultProps = {
    open: true,
    duplicateFolders: [mockFolder1, mockFolder2, mockFolder3],
    onClose: jest.fn(),
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the modal when open', () => {
    render(<DuplicateFoldersModal {...defaultProps} />)
    expect(screen.getByText('Duplicate folders are detected')).toBeInTheDocument()
  })

  it('does not render when closed', () => {
    render(<DuplicateFoldersModal {...defaultProps} open={false} />)
    expect(screen.queryByText('Duplicate folders are detected')).not.toBeInTheDocument()
  })

  it('displays warning message', () => {
    render(<DuplicateFoldersModal {...defaultProps} />)
    expect(
      screen.getByText(/Multiple folders with the same name exist in this location/i),
    ).toBeInTheDocument()
  })

  it('displays all duplicate folders', () => {
    render(<DuplicateFoldersModal {...defaultProps} />)
    expect(screen.getAllByText('Folder')).toHaveLength(3)
  })

  it('displays folder paths', () => {
    render(<DuplicateFoldersModal {...defaultProps} />)
    expect(screen.getAllByText(/course files \/ Folder/)).toHaveLength(3)
  })

  it('displays formatted creation dates', () => {
    render(<DuplicateFoldersModal {...defaultProps} />)
    const createdLabels = screen.getAllByText(/Created:/i)
    expect(createdLabels).toHaveLength(3)
  })

  it('calls onClose when close button is clicked', async () => {
    const user = userEvent.setup()
    render(<DuplicateFoldersModal {...defaultProps} />)

    const closeButton = screen.getByTestId('duplicate-folders-modal-close-button')
    await user.click(closeButton)

    expect(defaultProps.onClose).toHaveBeenCalledTimes(1)
  })

  it('calls onClose when X button is clicked', async () => {
    const user = userEvent.setup()
    render(<DuplicateFoldersModal {...defaultProps} />)

    // Find the X button (CloseButton) by its unique accessible name
    const xButton = screen.getByRole('button', {name: 'Close modal'})
    await user.click(xButton)

    expect(defaultProps.onClose).toHaveBeenCalled()
  })

  it('handles empty duplicates array', () => {
    render(<DuplicateFoldersModal {...defaultProps} duplicateFolders={[]} />)
    expect(screen.getByText('Duplicate folders are detected')).toBeInTheDocument()
    expect(screen.queryByText('Folder')).not.toBeInTheDocument()
  })
})
