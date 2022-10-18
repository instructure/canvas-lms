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

import clickCallback, {handleUpload} from '../clickCallback'
import {getAllByLabelText} from '@testing-library/react'
import FileSizeError from '@instructure/canvas-media/src/shared/FileSizeError'

const fauxEditor = {
  settings: {
    canvas_rce_user_context: {
      type: 'course',
      id: '17',
    },
  },
}

describe('handleUpload()', () => {
  let error, uploadData, onUploadComplete, uploadBookmark

  const subject = () => handleUpload(error, uploadData, onUploadComplete, uploadBookmark)

  beforeEach(() => {
    onUploadComplete = jest.fn()
  })

  describe('with a file size error', () => {
    beforeEach(() => {
      error = new FileSizeError({maxBytes: 1, actualBytes: 2})
    })

    it('calls onUploadComplete with the file size error', () => {
      subject()
      expect(onUploadComplete).toHaveBeenCalledWith(
        'Size of caption file is greater than the maximum 0.001 kb allowed file size.',
        uploadData
      )
    })
  })
})

describe('Instructure Media Plugin: clickCallback', () => {
  let trayProps
  beforeEach(() => {
    trayProps = {
      source: {
        initializeCollection() {},
        initializeUpload() {},
        initializeFlickr() {},
        initializeImages() {},
        initializeDocuments() {},
        initializeMedia() {},
      },
    }
  })
  afterEach(() => {
    document.querySelector('.canvas-rce-media-upload').remove()
  })

  it('adds the canvas-rce-upload-container element when opened', async () => {
    await clickCallback(fauxEditor, document, trayProps)
    expect(document.querySelector('.canvas-rce-media-upload')).toBeTruthy()
  })

  it('does not add the canvas-rce-upload-container element when opened if it exists already', async () => {
    const container = document.createElement('div')
    container.className = 'canvas-rce-upload-container'
    document.body.appendChild(container)
    await clickCallback(fauxEditor, document, trayProps)
    expect(document.querySelectorAll('.canvas-rce-media-upload').length).toEqual(1)
  })

  it('opens the UploadMedia modal when called', async () => {
    await clickCallback(fauxEditor, document, trayProps)
    expect(
      getAllByLabelText(document, 'Upload Media', {
        selector: '[role="dialog"]',
      })[0]
    ).toBeVisible()
  })
})
