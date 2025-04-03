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
import {render, screen, waitFor, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ZipFileImporter from '../zip_file'
import fetchMock from 'fetch-mock'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')

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

    expect(screen.getByText('Choose File')).toBeInTheDocument()
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
    expect(screen.queryByText('my_file.zip')).not.toBeInTheDocument()
  })

  it('renders alert when large file is chosen', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024 + 1})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)
    expect(screen.getByText('Your migration can not exceed 1.0 KB')).toBeInTheDocument()
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
      expect.any(Object),
    )
  })

  it('calls onCancel', async () => {
    renderComponent()

    await userEvent.click(screen.getByRole('button', {name: 'Clear'}))
    expect(onCancel).toHaveBeenCalled()
  })

  describe('search folders', () => {
    it('renders selected folder', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByText('Upload to')).toBeInTheDocument()
      })
      await userEvent.click(screen.getByText('course files'))
      await waitFor(() => {
        const {getByText} = within(screen.getByTestId('fileName'))
        expect(getByText('course files')).toBeInTheDocument()
      })
    })

    it('renders folder not selected message', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByText('Upload to')).toBeInTheDocument()
      })

      await waitFor(() => {
        const {getByText} = within(screen.getByTestId('fileName'))
        expect(getByText('No folder selected yet')).toBeInTheDocument()
      })
    })

    it('clears selected folder', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByText('Upload to')).toBeInTheDocument()
      })
      await userEvent.click(screen.getByText('course files'))

      await waitFor(() => {
        const {getByText} = within(screen.getByTestId('fileName'))
        expect(getByText('course files')).toBeInTheDocument()
      })

      await userEvent.click(screen.getByRole('button', {name: 'Remove folder'}))
      await waitFor(() => {
        const {getByText} = within(screen.getByTestId('fileName'))
        expect(getByText('No folder selected yet')).toBeInTheDocument()
      })
    })

    it('renders missing folder error', async () => {
      renderComponent()

      await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))

      expect(screen.getAllByText('Please select a folder')[0]).toBeInTheDocument()
    })

    describe('filter folder structure', () => {
      const searchAFolder = async (searchTerm: string) => {
        await waitFor(() => {
          expect(screen.getByText('Upload to')).toBeInTheDocument()
        })
        await userEvent.click(screen.getByText('course files'))
        await userEvent.type(screen.getByPlaceholderText('Search for a folder or file name...'), searchTerm)
        await userEvent.click(screen.getByRole('button', {name: 'Search', hidden: true}))
      }
      let container: HTMLElement
      const getExpectedAlertParams = (keyword: string) => ({
        politeness: 'polite',
        message: `Folder Tree Results Updated Below for ${keyword}`,
        srOnly: true,
        type: "info",
      })
      beforeEach(async () => {
        const wrapper = renderComponent()
        container = wrapper.container
      })

      it('does not have result', async () => {
        const keyword = 'wrong keyword'
        await searchAFolder(keyword)
        const listItems = container.querySelectorAll('[data-testid="folderTree"] ul li')

        expect(listItems).toHaveLength(0)
        expect(showFlashAlert).toHaveBeenLastCalledWith(getExpectedAlertParams(keyword))
      })

      it('has result', async () => {
        const keyword = 'course'
        await searchAFolder(keyword)
        const listItems = container.querySelectorAll('[data-testid="folderTree"] ul li')

        expect(listItems).toHaveLength(1)
        expect(showFlashAlert).toHaveBeenLastCalledWith(getExpectedAlertParams(keyword))
      })
    })
  })

  it('renders the progressbar info', async () => {
    renderComponent({isSubmitting: true, fileUploadProgress: 10})
    expect(screen.getByText('Uploading File')).toBeInTheDocument()
  })

  it('disable or hide inputs while uploading', async () => {
    renderComponent({isSubmitting: true})
    await waitFor(() => {
      expect(screen.getByTestId('migrationFileUpload')).toBeDisabled()
      expect(screen.getByRole('button', {name: 'Clear'})).toBeDisabled()
      expect(screen.getByRole('button', {name: /Adding.../})).toBeDisabled()
      expect(screen.queryByText('Search for a folder or file name...')).not.toBeInTheDocument()
      expect(screen.queryByText('course files')).not.toBeInTheDocument()
    })
  })

  describe('submit error', () => {
    describe('file input error', () => {
      const expectedFileMissingError = 'You must select a file to import content from'

      it('renders the file missing error', async () => {
        renderComponent()
        await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
        expect(screen.getByText(expectedFileMissingError)).toBeInTheDocument()
      })
    })
  })

  describe('focus after error', () => {
    it('focuses on input after file error', async () => {
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
      expect(screen.getByTestId('migrationFileUpload')).toHaveFocus()
    })

    it('focuses on input after folder error', async () => {
      renderComponent()
      const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
      const input = screen.getByTestId('migrationFileUpload')
      await userEvent.upload(input, file)
      await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
      expect(screen.getByPlaceholderText('Search for a folder or file name...')).toHaveFocus()
    })
  })
})
