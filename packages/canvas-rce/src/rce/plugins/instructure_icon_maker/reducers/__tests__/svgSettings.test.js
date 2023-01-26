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

import {svgSettings} from '../svgSettings'

describe('svgSettings()', () => {
  let initialState = {}
  const subject = action => svgSettings(initialState, action)

  it('handles "SetImageSettings"', () => {
    const imageSettings = {image: 'data:image/svg+xml;base64,PHN2Zaaaaaaaaa'}

    const nextState = subject({
      type: 'SetImageSettings',
      payload: imageSettings,
    })

    expect(nextState.imageSettings).toEqual(imageSettings)
  })

  it('handles "SetEmbedImage"', () => {
    const embedImage = 'data:image/svg+xml;base64,PHN2Zaaaaaaaaa'

    const nextState = subject({
      type: 'SetEmbedImage',
      payload: embedImage,
    })

    expect(nextState.embedImage).toEqual(embedImage)
  })

  it('handles "SetX"', () => {
    const x = 22

    const nextState = subject({
      type: 'SetX',
      payload: x,
    })

    expect(nextState.x).toEqual(x)
  })

  it('handles "SetY"', () => {
    const y = 22

    const nextState = subject({
      type: 'SetY',
      payload: y,
    })

    expect(nextState.y).toEqual(y)
  })

  it('handles "SetWidth"', () => {
    const width = 100

    const nextState = subject({
      type: 'SetWidth',
      payload: width,
    })

    expect(nextState.width).toEqual(width)
  })

  it('handles "SetHeight"', () => {
    const height = 10

    const nextState = subject({
      type: 'SetHeight',
      payload: height,
    })

    expect(nextState.height).toEqual(height)
  })

  it('handles "SetTranslateX"', () => {
    const nextState = subject({
      type: 'SetTranslateX',
      payload: 25,
    })

    expect(nextState.transform).toMatchInlineSnapshot(`"translate(25,undefined)"`)
  })

  it('handles "SetTranslateY"', () => {
    const nextState = subject({
      type: 'SetTranslateY',
      payload: 50,
    })

    expect(nextState.transform).toMatchInlineSnapshot(`"translate(undefined,50)"`)
  })

  describe('with an unrecognized action', () => {
    const type = 'FooBar'

    beforeEach(() => (initialState = {encodedImage: 'some encodedImage'}))

    it('does not modify the state', () => {
      const nextState = subject({type})

      expect(nextState).toMatchObject(initialState)
    })
  })
})
