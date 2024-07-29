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
import QTIZipImporter from '../qti_zip'

const onSubmit = jest.fn()
const onCancel = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(<QTIZipImporter onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

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
      expect(
        screen.getByRole('checkbox', {name: /Overwrite assessment content with matching IDs/})
      ).toBeDisabled()
    })
  })

  it('disable question bank inputs while uploading', async () => {
    const {getByRole, rerender, getByPlaceholderText} = renderComponent()

    await userEvent.click(getByRole('combobox', {name: 'Default Question bank'}))
    await userEvent.click(getByRole('option', {name: 'Create new question bank...'}))

    rerender(
      <QTIZipImporter
        onSubmit={onSubmit}
        onCancel={onCancel}
        isSubmitting={true}
        fileUploadProgress={10}
      />
    )

    await waitFor(() => {
      expect(getByPlaceholderText('New question bank')).toBeInTheDocument()
      expect(getByPlaceholderText('New question bank')).toBeDisabled()
      expect(getByRole('combobox', {name: 'Default Question bank'})).toBeDisabled()
    })
  })

  it('disable question bank inputs if "Import existing quizzes as New Quizzes" is checked', async () => {
    window.ENV.NEW_QUIZZES_MIGRATION = true
    window.ENV.NEW_QUIZZES_IMPORT = true
    window.ENV.QUIZZES_NEXT_ENABLED = true
    const {getByRole, queryByLabelText} = renderComponent()

    await userEvent.click(getByRole('combobox', {name: 'Default Question bank'}))
    await userEvent.click(getByRole('option', {name: 'Create new question bank...'}))
    await userEvent.click(getByRole('checkbox', {name: /Import existing quizzes as New Quizzes/}))

    await waitFor(() => {
      expect(getByRole('combobox', {name: 'Default Question bank'})).toBeInTheDocument()
      expect(getByRole('combobox', {name: 'Default Question bank'})).toBeDisabled()
      expect(queryByLabelText('New question bank')).not.toBeInTheDocument()
    })
  })
})
