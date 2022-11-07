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
  let settings, dispatch, image

  beforeEach(() => {
    settings = {
      shape: 'square',
      scaleRatio: 1,
      rotation: 0,
      translateX: 0,
      translateY: 0,
    }
    dispatch = jest.fn()
    image = 'https://www.fillmurray.com/640/480'
  })

  const subject = (otherProps = {}) =>
    render(<Preview settings={settings} dispatch={dispatch} image={image} {...otherProps} />)

  describe('renders', () => {
    it('the image', () => {
      const {container} = subject()
      expect(container.querySelector('img')).toBeInTheDocument()
    })

    it('the image with src', () => {
      const {container} = subject()
      expect(container.querySelector('img')).toMatchInlineSnapshot(`
      <img
        alt="Image to crop"
        src="https://www.fillmurray.com/640/480"
        style="height: 100%; object-fit: contain; text-align: center;"
      />
    `)
    })

    it('the crop shape container', () => {
      const {container} = subject()
      expect(container.querySelector('#cropShapeContainer')).toBeInTheDocument()
    })

    it('with rotate transform', () => {
      settings.rotation = 90
      const {container} = subject()
      expect(container.querySelector('img').style).toHaveProperty('transform', 'rotate(90deg)')
    })

    it('with scale transform', () => {
      settings.scaleRatio = 1.6
      const {container} = subject()
      expect(container.querySelector('img').style).toHaveProperty('transform', 'scale(1.6)')
    })

    it('with rotate and scale transform', () => {
      settings.rotation = 90
      settings.scaleRatio = 1.6
      const {container} = subject()
      expect(container.querySelector('img').style).toHaveProperty(
        'transform',
        'rotate(90deg) scale(1.6)'
      )
    })
  })

  it('changes the crop shape', () => {
    const {container, rerender} = subject()
    const svgContainer = container.querySelector('#cropShapeContainer')
    const squareContent = svgContainer.innerHTML
    settings.shape = 'octagon'
    rerender(<Preview settings={settings} dispatch={dispatch} image={image} />)
    const octagonContent = svgContainer.innerHTML
    expect(squareContent).not.toEqual(octagonContent)
  })

  describe('calls dispatch using wheel', () => {
    it('when zoom in', async () => {
      const {container} = subject()
      const event = {deltaY: -25}
      fireEvent.wheel(container.firstChild.firstChild, event)
      await waitFor(() => {
        expect(dispatch).toHaveBeenCalledWith({type: 'SetScaleRatio', payload: 1.13})
      })
    })

    it('when zoom out', async () => {
      settings.scaleRatio = 2
      const {container} = subject()
      const event = {deltaY: 25}
      fireEvent.wheel(container.firstChild.firstChild, event)
      await waitFor(() => {
        expect(dispatch).toHaveBeenCalledWith({type: 'SetScaleRatio', payload: 1.88})
      })
    })
  })

  describe('sets scale style using wheel', () => {
    it('when zoom in', async () => {
      const {container} = subject()
      const event = {deltaY: -25}
      fireEvent.wheel(container.firstChild.firstChild, event)
      await waitFor(() => {
        const img = container.querySelector('img')
        expect(img.style.transform).toEqual('scale(1.13)')
      })
    })

    it('when zoom out', async () => {
      settings.scaleRatio = 2
      const {container} = subject()
      const event = {deltaY: 25}
      fireEvent.wheel(container.firstChild.firstChild, event)
      await waitFor(() => {
        const img = container.querySelector('img')
        expect(img.style.transform).toEqual('scale(1.88)')
      })
    })
  })

  describe('listens arrow keys', () => {
    let container, event

    beforeEach(() => {
      const component = subject()
      document.querySelector('#cropper-preview').focus()
      container = component.container
      event = {preventDefault: jest.fn()}
    })

    describe('calls dispatch', () => {
      it('left', async () => {
        event.keyCode = 37
        fireEvent.keyDown(container.firstChild, event)
        await waitFor(() => {
          expect(dispatch).toHaveBeenCalledWith({type: 'SetTranslateX', payload: -1})
        })
      })

      it('up', async () => {
        event.keyCode = 38
        fireEvent.keyDown(container.firstChild, event)
        await waitFor(() => {
          expect(dispatch).toHaveBeenCalledWith({type: 'SetTranslateY', payload: -1})
        })
      })

      it('right', async () => {
        event.keyCode = 39
        fireEvent.keyDown(container.firstChild, event)
        await waitFor(() => {
          expect(dispatch).toHaveBeenCalledWith({type: 'SetTranslateX', payload: 1})
        })
      })

      it('down', async () => {
        event.keyCode = 40
        fireEvent.keyDown(container.firstChild, event)
        await waitFor(() => {
          expect(dispatch).toHaveBeenCalledWith({type: 'SetTranslateY', payload: 1})
        })
      })
    })

    describe('sets translate style', () => {
      it('left', async () => {
        event.keyCode = 37
        fireEvent.keyDown(container.firstChild, event)
        await waitFor(() => {
          const img = container.querySelector('img')
          expect(img.style.transform).toEqual('translateX(-1px)')
        })
      })

      it('up', async () => {
        event.keyCode = 38
        fireEvent.keyDown(container.firstChild, event)
        await waitFor(() => {
          const img = container.querySelector('img')
          expect(img.style.transform).toEqual('translateY(-1px)')
        })
      })

      it('right', async () => {
        event.keyCode = 39
        fireEvent.keyDown(container.firstChild, event)
        await waitFor(() => {
          const img = container.querySelector('img')
          expect(img.style.transform).toEqual('translateX(1px)')
        })
      })

      it('down', async () => {
        event.keyCode = 40
        fireEvent.keyDown(container.firstChild, event)
        await waitFor(() => {
          const img = container.querySelector('img')
          expect(img.style.transform).toEqual('translateY(1px)')
        })
      })
    })
  })

  describe('listens mouse dragging', () => {
    let container, target, mouseDownEvent, mouseMoveEvent, mouseUpEvent

    beforeAll(() => {
      mouseDownEvent = {target}
      mouseMoveEvent = {clientX: 15, clientY: 30}
      mouseUpEvent = {target}
    })

    beforeEach(() => {
      const component = subject()
      container = component.container
      target = container.querySelector('img')

      fireEvent.mouseDown(target, mouseDownEvent)
      fireEvent.mouseMove(target, mouseMoveEvent)
      fireEvent.mouseUp(target, mouseUpEvent)
    })

    describe('calls dispatch', () => {
      it('when dragging once', async () => {
        await waitFor(() => {
          expect(dispatch).toHaveBeenCalledWith({type: 'SetTranslateX', payload: 15})
          expect(dispatch).toHaveBeenCalledWith({type: 'SetTranslateY', payload: 30})
        })
      })

      it('when dragging and reuses previous position', async () => {
        fireEvent.mouseDown(target, mouseDownEvent)
        fireEvent.mouseMove(target, mouseMoveEvent)
        fireEvent.mouseUp(target, mouseUpEvent)

        await waitFor(() => {
          expect(dispatch).toHaveBeenCalledWith({type: 'SetTranslateX', payload: 30})
          expect(dispatch).toHaveBeenCalledWith({type: 'SetTranslateY', payload: 60})
        })
      })
    })

    describe('sets translate style', () => {
      it('when dragging once', async () => {
        await waitFor(() => {
          expect(target.style.transform).toEqual('translateX(15px) translateY(30px)')
        })
      })

      it('when dragging and reuses previous position', async () => {
        fireEvent.mouseDown(target, mouseDownEvent)
        fireEvent.mouseMove(target, mouseMoveEvent)
        fireEvent.mouseUp(target, mouseUpEvent)

        await waitFor(() => {
          expect(target.style.transform).toEqual('translateX(30px) translateY(60px)')
        })
      })
    })
  })
})
