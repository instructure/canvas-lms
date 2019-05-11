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

import clickCallback from '../clickCallback'
import {getByLabelText} from 'react-testing-library'

describe('Instructure Image Plugin: clickCallback', () => {
  afterEach(() => {
    document.querySelector('.canvas-rce-image-upload').remove()
  })

  it('adds the canvas-rce-image-upload element when opened', async () => {
    await clickCallback({}, document)
    expect(document.querySelector('.canvas-rce-image-upload')).toBeTruthy()
  })

  it('does not add the canvas-rce-image-upload element when opened if it exists already', async () => {
    const container = document.createElement('div')
    container.className = 'canvas-rce-image-upload'
    document.body.appendChild(container)
    await clickCallback({}, document)
    expect(document.querySelectorAll('.canvas-rce-image-upload').length).toEqual(1)
  })

  it('opens the UploadImage modal when called', async () => {
    await clickCallback({}, document)
    expect(
      getByLabelText(document, 'Upload Image', {
        selector: 'form'
      })
    ).toBeVisible()
  })
})
