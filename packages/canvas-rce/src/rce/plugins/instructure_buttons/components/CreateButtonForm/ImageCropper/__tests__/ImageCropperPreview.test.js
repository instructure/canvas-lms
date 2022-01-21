/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render} from '@testing-library/react'

import ImageCropperPreview from '../ImageCropperPreview'

describe('ImageCropperPreview', () => {
  it('renders the image', () => {
    const {container} = render(
      <ImageCropperPreview shape="square" image="https://www.fillmurray.com/640/480" />
    )
    expect(container.querySelector('img')).toBeInTheDocument()
  })

  it('renders the image with src', () => {
    const {container} = render(
      <ImageCropperPreview shape="square" image="https://www.fillmurray.com/640/480" />
    )
    expect(container.querySelector('img')).toMatchInlineSnapshot(`
      <img
        alt="Image to crop"
        src="https://www.fillmurray.com/640/480"
        style="position: absolute; top: 0px; left: 0px; height: 100%; width: 100%; object-fit: contain; text-align: center; cursor: move;"
      />
    `)
  })

  it('renders the crop shape container', () => {
    const {container} = render(
      <ImageCropperPreview shape="square" image="https://www.fillmurray.com/640/480" />
    )
    expect(container.querySelector('#cropShapeContainer')).toBeInTheDocument()
  })

  it('changes the crop shape', () => {
    const {container, rerender} = render(
      <ImageCropperPreview shape="square" image="https://www.fillmurray.com/640/480" />
    )
    const svgContainer = container.querySelector('#cropShapeContainer')
    const squareContent = svgContainer.innerHTML
    rerender(<ImageCropperPreview shape="octagon" image="https://www.fillmurray.com/640/480" />)
    const octagonContent = svgContainer.innerHTML
    expect(squareContent).not.toEqual(octagonContent)
  })
})
