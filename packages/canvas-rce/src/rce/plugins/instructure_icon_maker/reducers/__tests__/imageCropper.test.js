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

import {cropperSettingsReducer} from '../imageCropper'

describe('cropperSettingsReducer()', () => {
  let initialState = {}
  const subject = action => cropperSettingsReducer(initialState, action)

  it('handles "SetImage" actions', () => {
    const nextState = subject({
      type: 'SetImage',
      payload: 'data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==',
    })

    expect(nextState).toMatchObject({
      image: 'data:text/plain;base64,SGVsbG8sIFdvcmxkIQ==',
    })
  })

  it('handles "SetShape" actions', () => {
    const nextState = subject({
      type: 'SetShape',
      payload: 'circle',
    })

    expect(nextState).toMatchObject({
      shape: 'circle',
    })
  })

  it('handles "SetScaleRatio" actions', () => {
    const nextState = subject({
      type: 'SetScaleRatio',
      payload: 1.5,
    })

    expect(nextState).toMatchObject({
      scaleRatio: 1.5,
    })
  })

  describe('with an unrecognized action', () => {
    initialState = {image: 'some encoded image'}
    const nextState = () =>
      subject({
        type: 'FooBar',
        payload: 'banana',
      })
    expect(nextState).toThrow(Error)
  })
})
