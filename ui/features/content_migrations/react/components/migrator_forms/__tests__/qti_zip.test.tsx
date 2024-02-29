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
import {render, screen} from '@testing-library/react'
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
    renderComponent({fileUploadProgress: 10})
    expect(screen.getByText('Uploading File')).toBeInTheDocument()
  })
})
