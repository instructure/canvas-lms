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
import CanvasCartridgeImporter from '../canvas_cartridge'

const onSubmit = jest.fn()
const onCancel = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(<CanvasCartridgeImporter onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

describe('CanvasCartridgeImporter', () => {
  beforeAll(() => (window.ENV.UPLOAD_LIMIT = 1024))

  afterEach(() => jest.clearAllMocks())

  it('calls onSubmit', async () => {
    renderComponent()

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)
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

  it('renders the progressbar info', async () => {
    renderComponent({isSubmitting: true, fileUploadProgress: 10})
    expect(screen.getByText('Uploading File')).toBeInTheDocument()
  })

  it('disable inputs while uploading', async () => {
    renderComponent({isSubmitting: true})
    await waitFor(() => {
      expect(screen.getByTestId('migrationFileUpload')).toBeDisabled()
      expect(screen.getByRole('button', {name: 'Cancel'})).toBeDisabled()
      expect(screen.getByRole('button', {name: /Adding.../})).toBeDisabled()
      expect(screen.getByRole('radio', {name: /All content/})).toBeDisabled()
      expect(screen.getByRole('radio', {name: 'Select specific content'})).toBeDisabled()
      expect(screen.getByRole('checkbox', {name: 'Adjust events and due dates'})).toBeDisabled()
    })
  })

  it('disable "Adjust events and due dates" inputs while uploading', async () => {
    const {getByRole, rerender, getByLabelText} = renderComponent()

    await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

    rerender(
      <CanvasCartridgeImporter
        onSubmit={onSubmit}
        onCancel={onCancel}
        isSubmitting={true}
        fileUploadProgress={10}
      />
    )

    await waitFor(() => {
      expect(getByRole('radio', {name: 'Shift dates'})).toBeInTheDocument()
      expect(getByRole('radio', {name: 'Shift dates'})).toBeDisabled()
      expect(getByRole('radio', {name: 'Remove dates'})).toBeDisabled()
      expect(getByLabelText('Select original beginning date')).toBeDisabled()
      expect(getByLabelText('Select new beginning date')).toBeDisabled()
      expect(getByLabelText('Select original end date')).toBeDisabled()
      expect(getByLabelText('Select new end date')).toBeDisabled()
      expect(getByRole('button', {name: 'Add substitution'})).toBeDisabled()
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
})
