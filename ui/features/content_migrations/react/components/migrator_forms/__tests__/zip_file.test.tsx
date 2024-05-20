/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import ZipFileImporter from '../zip_file'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import fetchMock from 'fetch-mock'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn().mockReturnValue(jest.fn()),
}))

const onSubmit = jest.fn()
const onCancel = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(<ZipFileImporter onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

describe('ZipFileImporter', () => {
  beforeEach(() => {
    window.ENV.UPLOAD_LIMIT = 1024
    window.ENV.COURSE_ID = '1'
    fetchMock.mock('/api/v1/courses/1/folders?sort_by=position&per_page=100', [
      {
        id: '1',
        name: 'course files',
        full_name: 'course files',
        context_id: '1',
        context_type: 'Course',
        parent_folder_id: null,
        workflow_state: 'visible',
        created_at: '2023-10-17T15:50:09Z',
        updated_at: '2023-10-17T15:50:09Z',
        deleted_at: null,
        locked: null,
        lock_at: null,
        unlock_at: null,
        cloned_item_id: null,
        position: null,
        folders_url: null,
        files_url: null,
        files_count: null,
        folders_count: null,
        hidden: false,
        hidden_for_user: false,
        locked_for_user: false,
        for_submissions: false,
        can_upload: true,
        children: [],
      },
    ])
  })

  afterEach(() => {
    jest.clearAllMocks()
    fetchMock.restore()
  })

  it('renders hidden input', () => {
    renderComponent()

    expect(screen.getByTestId('migrationFileUpload')).toBeInTheDocument()
  })

  it('renders button input', () => {
    renderComponent()

    expect(screen.getByRole('button', {name: 'Choose File'})).toBeInTheDocument()
  })

  it('renders text if no file is chosen', () => {
    renderComponent()

    expect(screen.getByText('No file chosen')).toBeInTheDocument()
  })

  it('renders file name if file is chosen', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)
    expect(screen.getByText('my_file.zip')).toBeInTheDocument()
  })

  it('does not render file name when large file is chosen', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024 + 1})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)
    expect(screen.getByText('No file chosen')).toBeInTheDocument()
  })

  it('renders alert when large file is chosen', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024 + 1})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)
    expect(showFlashError).toHaveBeenCalledWith('Your migration can not exceed 1.0 KB')
  })

  it('calls onSubmit', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)
    await userEvent.click(screen.getByText('course files'))
    await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        pre_attachment: {
          name: 'my_file.zip',
          no_redirect: true,
          size: 16,
        },
      }),
      expect.any(Object)
    )
  })

  it('calls onCancel', async () => {
    renderComponent()

    await userEvent.click(screen.getByRole('button', {name: 'Cancel'}))
    expect(onCancel).toHaveBeenCalled()
  })

  it('renders folder select', async () => {
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Upload to')).toBeInTheDocument()
    })
    await userEvent.click(screen.getByText('course files'))
    await waitFor(() => {
      expect(screen.getByText('course files')).toBeInTheDocument()
    })
  })

  it('renders the progressbar info', async () => {
    renderComponent({fileUploadProgress: 10})
    expect(screen.getByText('Uploading File')).toBeInTheDocument()
  })
})
