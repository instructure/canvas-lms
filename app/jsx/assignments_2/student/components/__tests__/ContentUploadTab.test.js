/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import ContentUploadTab from '../ContentUploadTab'
import {DEFAULT_ICON} from '../../../../shared/helpers/mimeClassIconHelper'
import {fireEvent, render} from 'react-testing-library'
import React from 'react'

beforeEach(() => {
  window.URL.createObjectURL = jest.fn()
})

describe('ContentUploadTab', () => {
  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files
      }
    })
  }

  it('renders the empty upload tab by default', async () => {
    const {container, getByTestId, getByText} = render(<ContentUploadTab />)
    const emptyRender = getByTestId('empty-upload')

    expect(emptyRender).toContainElement(getByText('Upload File'))
    expect(emptyRender).toContainElement(
      container.querySelector(`svg[name=${DEFAULT_ICON.type.displayName}]`)
    )
  })

  it('renders the uploaded files if there are any', async () => {
    const {container, getByTestId, getByText} = render(<ContentUploadTab />)
    const emptyRender = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'awesome-test-image.png', {type: 'image/png'})

    uploadFiles(emptyRender, [file])
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(getByText('awesome-test-image.png'))
  })

  it('renders in an img tag if an image is uploaded', async () => {
    const {container, getByTestId} = render(<ContentUploadTab />)
    const emptyRender = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'awesome-test-image.png', {type: 'image/png'})

    uploadFiles(emptyRender, [file])
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(
      container.querySelector('img[alt="awesome-test-image.png preview"]')
    )
    expect(container.querySelector('svg[name*="Icon"]')).toBeNull()
  })

  it('renders an icon if a non-image file is uploaded', async () => {
    const {container, getByTestId} = render(<ContentUploadTab />)
    const emptyRender = container.querySelector('input[type="file"]')
    const file = new File(['foo'], 'awesome-test-file.pdf', {type: 'application/pdf'})

    uploadFiles(emptyRender, [file])
    const uploadRender = getByTestId('non-empty-upload')

    expect(uploadRender).toContainElement(container.querySelector('svg[name="IconPdf"]'))
    expect(container.querySelector('img[alt="awesome-test-file.pdf preview"]')).toBeNull()
  })
})
