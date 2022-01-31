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

describe('ImageCropPreview', () => {
  it('renders the image', () => {
    const {container} = render(<ImageCropperPreview shape="square" />)
    expect(container.querySelector('img')).toBeInTheDocument()
  })

  it('renders the crop shape container', () => {
    const {container, rerender} = render(<ImageCropperPreview shape="square" />)
    expect(container.querySelector('#cropShapeContainer')).toBeInTheDocument()
  })

  it('changes the crop shape', () => {
    const {container, rerender} = render(<ImageCropperPreview shape="square" />)
    const svgContainer = container.querySelector('#cropShapeContainer')
    const squareContent = svgContainer.innerHTML
    rerender(<ImageCropperPreview shape="octagon" />)
    const octagonContent = svgContainer.innerHTML
    expect(squareContent).not.toEqual(octagonContent)
  })
})
