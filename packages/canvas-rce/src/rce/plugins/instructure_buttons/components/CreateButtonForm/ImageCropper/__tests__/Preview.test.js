/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'

import {Preview} from '../Preview'

describe('Preview', () => {
  let settings, dispatch

  beforeEach(() => {
    settings = {
      image: 'https://www.fillmurray.com/640/480',
      shape: 'square',
      scaleRatio: 1
    }
    dispatch = jest.fn()
  })

  describe('renders', () => {
    it('the image', () => {
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      expect(container.querySelector('img')).toBeInTheDocument()
    })

    it('the image with src', () => {
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      expect(container.querySelector('img')).toMatchInlineSnapshot(`
      <img
        alt="Image to crop"
        src="https://www.fillmurray.com/640/480"
        style="position: absolute; top: 0px; left: 0px; height: 100%; width: 100%; object-fit: contain; text-align: center;"
      />
    `)
    })

    it('the crop shape container', () => {
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      expect(container.querySelector('#cropShapeContainer')).toBeInTheDocument()
    })

    it('with rotate transform', () => {
      settings.rotation = 90
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      expect(container.querySelector('img').style).toHaveProperty('transform', 'rotate(90deg)')
    })

    it('with scale transform', () => {
      settings.scaleRatio = 1.6
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      expect(container.querySelector('img').style).toHaveProperty('transform', 'scale(1.6)')
    })

    it('with rotate and scale transform', () => {
      settings.rotation = 90
      settings.scaleRatio = 1.6
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      expect(container.querySelector('img').style).toHaveProperty(
        'transform',
        'rotate(90deg) scale(1.6)'
      )
    })
  })

  it('changes the crop shape', () => {
    const {container, rerender} = render(<Preview settings={settings} dispatch={dispatch} />)
    const svgContainer = container.querySelector('#cropShapeContainer')
    const squareContent = svgContainer.innerHTML
    settings.shape = 'octagon'
    rerender(<Preview settings={settings} dispatch={dispatch} />)
    const octagonContent = svgContainer.innerHTML
    expect(squareContent).not.toEqual(octagonContent)
  })

  describe('calls dispatch using wheel', () => {
    it('when zoom in', async () => {
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      const event = {deltaY: -25}
      fireEvent.wheel(container.firstChild, event)
      await waitFor(() => {
        expect(dispatch).toHaveBeenCalledWith({type: 'SetScaleRatio', payload: 1.125})
      })
    })

    it('when zoom out', async () => {
      settings.scaleRatio = 2
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      const event = {deltaY: 25}
      fireEvent.wheel(container.firstChild, event)
      await waitFor(() => {
        expect(dispatch).toHaveBeenCalledWith({type: 'SetScaleRatio', payload: 1.875})
      })
    })
  })

  describe('sets scale style using wheel', () => {
    it('when zoom in', async () => {
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      const event = {deltaY: -25}
      fireEvent.wheel(container.firstChild, event)
      await waitFor(() => {
        const img = container.querySelector('img')
        expect(img.style.transform).toEqual('scale(1.125)')
      })
    })

    it('when zoom out', async () => {
      settings.scaleRatio = 2
      const {container} = render(<Preview settings={settings} dispatch={dispatch} />)
      const event = {deltaY: 25}
      fireEvent.wheel(container.firstChild, event)
      await waitFor(() => {
        const img = container.querySelector('img')
        expect(img.style.transform).toEqual('scale(1.875)')
      })
    })
  })
})
