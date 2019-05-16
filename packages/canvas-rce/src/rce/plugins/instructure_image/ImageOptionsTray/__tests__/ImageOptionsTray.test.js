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

import React from 'react'
import {render} from 'react-testing-library'

import ImageOptionsTray from '..'

describe('RCE "Images" Plugin > ImageOptionsTray', () => {
  let $image
  let component
  let props

  beforeEach(() => {
    $image = document.createElement('img')
    $image.src = 'http://localhost/image.jpg'
    document.body.appendChild($image)

    props = {
      imageElement: $image,
      onRequestClose: jest.fn(),
      open: true
    }
  })

  afterEach(() => {
    $image.remove()
  })

  function renderComponent() {
    component = render(<ImageOptionsTray {...props} />)
  }

  function getTray() {
    return component.queryByRole('dialog')
  }

  it('is optionally rendered open', async () => {
    props.open = true
    renderComponent()
    expect(getTray()).toBeInTheDocument()
  })

  it('is optionally rendered closed', async () => {
    props.open = false
    renderComponent()
    expect(getTray()).not.toBeInTheDocument()
  })

  describe('Tray Label', () => {
    beforeEach(renderComponent)

    function getTrayLabel() {
      return getTray().getAttribute('aria-label')
    }

    it('is labeled with "Image Options Tray"', () => {
      expect(getTrayLabel()).toEqual('Image Options Tray')
    })
  })
})
