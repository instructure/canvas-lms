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

import bridge from '../../../../bridge'
import clickCallback from '../clickCallback'
import {getAllByLabelText} from '@testing-library/react'

describe('Instructure Image Plugin: clickCallback', () => {
  let trayProps
  const editor = {
    getParam: () => {},
  }

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
    bridge.trayProps.set(editor, trayProps)
  })
  afterEach(() => {
    document.querySelector('.canvas-rce-upload-container').remove()
  })

  it('adds the canvas-rce-upload-container element when opened', async () => {
    await clickCallback(editor, document, trayProps)
    expect(document.querySelector('.canvas-rce-upload-container')).toBeTruthy()
  })

  it('does not add the canvas-rce-upload-container element when opened if it exists already', async () => {
    const container = document.createElement('div')
    container.className = 'canvas-rce-upload-container'
    document.body.appendChild(container)
    await clickCallback(editor, document, trayProps)
    expect(document.querySelectorAll('.canvas-rce-upload-container').length).toEqual(1)
  })

  it('opens the UploadImage modal when called', async () => {
    await clickCallback(editor, document, trayProps)
    expect(
      getAllByLabelText(document, 'Upload Image', {
        selector: 'form',
      })[0]
    ).toBeVisible()
  })
})
