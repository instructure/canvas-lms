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

import {DEFAULT_CROPPER_SETTINGS} from '../constants'

export const defaultState = DEFAULT_CROPPER_SETTINGS

export const actions = {
  SET_SHAPE: 'SetShape',
  SET_ROTATION: 'SetRotation',
  SET_SCALE_RATIO: 'SetScaleRatio',
  SET_TRANSLATE_X: 'SetTranslateX',
  SET_TRANSLATE_Y: 'SetTranslateY',
  UPDATE_SETTINGS: 'UpdateSettings',
  RESET_SETTINGS: 'ResetSettings',
}

export const cropperSettingsReducer = (state, action) => {
  switch (action.type) {
    case actions.SET_SHAPE:
      return {...state, shape: action.payload}
    case actions.SET_ROTATION:
      return {...state, rotation: action.payload}
    case actions.SET_SCALE_RATIO:
      return {...state, scaleRatio: action.payload}
    case actions.SET_TRANSLATE_X:
      return {...state, translateX: action.payload}
    case actions.SET_TRANSLATE_Y:
      return {...state, translateY: action.payload}
    case actions.UPDATE_SETTINGS:
      return {...state, ...action.payload}
    case actions.RESET_SETTINGS:
      return {
        ...state,
        rotation: defaultState.rotation,
        scaleRatio: defaultState.scaleRatio,
        translateX: defaultState.translateX,
        translateY: defaultState.translateY,
      }
    default:
      throw Error('Unknown action for image cropper reducer')
  }
}
