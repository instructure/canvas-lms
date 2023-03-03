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

import {renderImage} from '../../../../contentRendering'
import Image from '../Image'

describe('RCE "Images" Plugin > Image', () => {
  let component
  let props

  beforeEach(() => {
    props = {
      image: {
        display_name: 'Example Image',
        filename: 'example.png',
        href: 'http://canvas.rce/images/example.png',
        id: 123,
        preview_url: 'http://canvas.rce/images/preview/example.png',
        thumbnail_url: 'http://canvas.rce/images/thumbnail/example.png',
      },
      onClick: jest.fn(),
      canvasOrigin: 'https://canvas.instructor.com',
    }
  })

  function SpecComponent() {
    // `useRef()` can only be used within a component render
    props.focusRef = useRef(null)

    return <Image {...props} />
  }

  function renderComponent() {
    component = render(<SpecComponent />)
  }

  function getFocusable() {
    return component.container.querySelector('a,button')
  }

  function getImage() {
    return component.getByAltText(props.image.display_name)
  }

  it('renders an img', () => {
    renderComponent()
    expect(getImage()).toBeInTheDocument()
  })

  it('uses the image thumbnail url for the img src', () => {
    renderComponent()
    expect(getImage().getAttribute('src')).toEqual(props.image.thumbnail_url)
  })

  it('uses the image display name for the img alt text', () => {
    renderComponent()
    expect(getImage().getAttribute('alt')).toEqual(props.image.display_name)
  })

  it('uses the image display name for the img title', () => {
    renderComponent()
    expect(getImage().getAttribute('title')).toMatch(props.image.display_name)
  })

  it('forwards the .focusRef prop to the anchor component', () => {
    renderComponent()
    expect(props.focusRef.current).toEqual(getFocusable())
  })

  describe('when clicked', () => {
    it('calls the .onClick prop', () => {
      renderComponent()
      fireEvent.click(getImage())
      expect(props.onClick).toHaveBeenCalledTimes(1)
    })

    it('includes the .image prop when calling the .onClick prop', () => {
      renderComponent()
      fireEvent.click(getImage())
      expect(props.onClick).toHaveBeenCalledWith(props.image)
    })

    it('prevents the default click handler', () => {
      const preventDefault = jest.fn()
      renderComponent()
      // Override preventDefault before event reaches image
      getFocusable().addEventListener(
        'click',
        event => {
          Object.assign(event, {preventDefault})
        },
        true
      )
      fireEvent.click(getImage())
      expect(preventDefault).toHaveBeenCalledTimes(1)
    })
  })

  describe('when drag starts', () => {
    let imageData

    beforeEach(() => {
      imageData = null
    })

    function dragStart($element) {
      const event = new Event('dragstart', {bubbles: true})
      Object.assign(event, {
        dataTransfer: buildDataTransfer(),
      })
      $element.dispatchEvent(event)
    }

    function buildDataTransfer() {
      return {
        getData() {
          return `<img src="http://canvas.docker/images/thumbnails/show/55/BI8re30hgKqgYgEYMf8AwTr7wvFjqFSdSZvNU96R">`
        },
        setData(type, data) {
          imageData = {type, data}
        },
      }
    }

    it('sets the dataTransfer data to a render of the image', () => {
      renderComponent()
      dragStart(getImage())
      expect(imageData.data).toEqual(renderImage(props.image))
    })

    it('sets the dataTransfer type to text/html', () => {
      renderComponent()
      dragStart(getImage())
      expect(imageData.type).toEqual('text/html')
    })
  })
})
