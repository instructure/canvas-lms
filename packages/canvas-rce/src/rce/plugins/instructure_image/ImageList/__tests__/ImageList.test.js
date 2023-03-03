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

import React, {useRef} from 'react'
import {fireEvent, render} from '@testing-library/react'

import {buildImage} from '../../../../../rcs/fake'
import ImageList from '..'

describe('RCE "Images" Plugin > ImageList', () => {
  let component
  let props

  beforeEach(() => {
    props = {
      images: [
        buildImage(0, 'example_1.png', 100, 200),
        buildImage(1, 'example_2.png', 101, 201),
        buildImage(2, 'example_3.png', 102, 202),
      ],
      onImageClick: jest.fn(),
      canvasOrigin: 'https://canvas.instructor.com',
    }
  })

  function SpecComponent() {
    // `useRef()` can only be used within a component render
    props.lastItemRef = useRef(null)

    return <ImageList {...props} />
  }

  function renderComponent() {
    component = render(<SpecComponent />)
  }

  function getImages() {
    return component.container.querySelectorAll('img')
  }

  it('includes an `img` element for each image in the list', () => {
    renderComponent()
    expect(getImages()).toHaveLength(3)
  })

  describe('.lastItemRef prop', () => {
    it('is used when there are images', () => {
      renderComponent()
      expect(props.lastItemRef.current).toBeInTheDocument()
    })

    it('is forwarded to the last image', () => {
      renderComponent()
      const $item = props.lastItemRef.current
      const {src} = $item.querySelector('img')
      expect(src).toEqual(props.images[2].href)
    })

    it('is not used when the images list is empty', () => {
      props.images = []
      renderComponent()
      expect(props.lastItemRef.current).toBeNull()
    })
  })

  it('calls the .onImageClick prop with the related image when clicked', () => {
    renderComponent()
    fireEvent.click(getImages()[1])
    expect(props.onImageClick).toHaveBeenCalledWith(props.images[1])
  })
})
