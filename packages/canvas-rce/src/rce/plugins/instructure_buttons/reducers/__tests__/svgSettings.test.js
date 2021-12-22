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

  it('handles "SetEncodedImage" actions', () => {
    const dataUrl = 'data:text/plain;base64,SGVsbG8sIFdvcmxkIQ=='

    const nextState = subject({
      type: 'SetEncodedImage',
      payload: dataUrl
    })

    expect(nextState).toMatchObject({
      encodedImage: dataUrl
    })
  })

  it('handles "SetEncodedImageType" actions', () => {
    const type = 'course'

    const nextState = subject({
      type: 'SetEncodedImageType',
      payload: type
    })

    expect(nextState.encodedImageType).toEqual(type)
  })

  it('handles "SetEncodedImageName" actions', () => {
    const name = 'banana.jpg'

    const nextState = subject({
      type: 'SetEncodedImageName',
      payload: name
    })

    expect(nextState.encodedImageName).toEqual(name)
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
