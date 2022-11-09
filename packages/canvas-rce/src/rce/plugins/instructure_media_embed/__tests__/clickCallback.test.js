/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {getAllByLabelText} from '@testing-library/react'

const fauxEditor = {
  settings: {
    canvas_rce_user_context: {
      type: 'course',
      id: '17',
    },
  },
}

describe('instructure_media_embed clickCallback', () => {
  afterEach(() => {
    document.querySelector('.canvas-rce-embed-container').remove()
  })

  it('adds the canvas-rce-embed-container element when opened', async () => {
    await clickCallback(fauxEditor, document)
    expect(document.querySelector('.canvas-rce-embed-container')).toBeTruthy()
  })

  it('does not add the canvas-rce-embed-container element when opened if it exists already', async () => {
    const container = document.createElement('div')
    container.className = 'canvas-rce-embed-container'
    document.body.appendChild(container)
    await clickCallback(fauxEditor, document)
    expect(document.querySelectorAll('.canvas-rce-embed-container').length).toEqual(1)
  })

  it('opens the Embed modal when called', async () => {
    await clickCallback(fauxEditor, document)
    expect(
      getAllByLabelText(document, 'Embed', {
        selector: '[role="dialog"]',
      })[0]
    ).toBeVisible()
  })
})
