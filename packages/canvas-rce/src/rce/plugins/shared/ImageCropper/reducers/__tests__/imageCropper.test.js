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

  it('handles "SetShape" actions', () => {
    const nextState = subject({
      type: 'SetShape',
      payload: 'circle',
    })

    expect(nextState).toMatchObject({
      shape: 'circle',
    })
  })

  it('handles "SetRotation" actions', () => {
    const nextState = subject({
      type: 'SetRotation',
      payload: 90,
    })

    expect(nextState).toMatchObject({
      rotation: 90,
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

  it('handles "SetTranslateX" actions', () => {
    const nextState = subject({
      type: 'SetTranslateX',
      payload: 100,
    })

    expect(nextState).toMatchObject({
      translateX: 100,
    })
  })

  it('handles "SetTranslateY" actions', () => {
    const nextState = subject({
      type: 'SetTranslateY',
      payload: 100,
    })

    expect(nextState).toMatchObject({
      translateY: 100,
    })
  })

  it('handles "UpdateSettings" actions', () => {
    const nextState = subject({
      type: 'UpdateSettings',
      payload: {translateX: 100, translateY: 100},
    })

    expect(nextState).toMatchObject({
      translateX: 100,
      translateY: 100,
    })
  })

  it('handles "ResetSettings" actions', () => {
    const nextState = subject({
      type: 'ResetSettings',
    })

    expect(nextState).toMatchObject({
      rotation: 0,
      scaleRatio: 1.0,
      translateX: 0,
      translateY: 0,
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
