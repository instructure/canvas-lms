/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import * as uploadFileModule from '@canvas/upload-file'
import {render, fireEvent} from '@testing-library/react'

import {FileAttachmentUpload} from '../FileAttachmentUpload'

const setup = (onAddItem = jest.fn()) => {
  return render(<FileAttachmentUpload onAddItem={onAddItem} />)
}

// VICE-4065 - remove or rewrite to remove spies on uploadFileModule import
describe.skip('FileAttachmentUpload', () => {
  beforeEach(() => {
    uploadFileModule.uploadFiles = jest.fn().mockResolvedValue([])
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders', async () => {
    const {findByTestId} = setup()

    expect(await findByTestId('attachment-upload')).toBeInTheDocument()
    expect(await findByTestId('attachment-input')).toBeInTheDocument()
  })

  it('button passes .click to input', async () => {
    const {findByTestId} = setup()
    const button = await findByTestId('attachment-upload')
    const input = await findByTestId('attachment-input')
    input.click = jest.fn()

    button.click()

    expect(input.click).toHaveBeenCalled()
  })

  it('input handles file upload', async () => {
    const mockOnAddItem = jest.fn()
    const {findByTestId} = setup(mockOnAddItem)
    const input = await findByTestId('attachment-input')
    const fileEvent = {
      target: {
        files: [new File(['FakeFile'], 'FakeFile.pdf', {type: 'application/pdf'})],
      },
    }

    fireEvent.change(input, fileEvent)

    expect(mockOnAddItem).toHaveBeenCalled()
  })
})
