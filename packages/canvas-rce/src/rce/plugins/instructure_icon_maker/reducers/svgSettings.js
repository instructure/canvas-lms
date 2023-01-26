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

import {DEFAULT_SETTINGS} from '../svg/constants'

export const defaultState = DEFAULT_SETTINGS

export const actions = {
  SET_IMAGE_SETTINGS: 'SetImageSettings',
  SET_EMBED_IMAGE: 'SetEmbedImage',
  SET_X: 'SetX',
  SET_Y: 'SetY',
  SET_TRANSLATE_X: 'SetTranslateX',
  SET_TRANSLATE_Y: 'SetTranslateY',
  SET_WIDTH: 'SetWidth',
  SET_HEIGHT: 'SetHeight',
  SET_ERROR: 'SetError',
}

const buildTransformString = state => {
  // All transforms that may be applied to an image
  return [`translate(${state.translateX},${state.translateY})`].join(' ')
}

const nextStateForTransform = (currentState, transformProp, value) => {
  // Set the transform property that actually changed
  let nextState = {...currentState, [transformProp]: value}

  // Regenerate the new "transform" string, taking into account the transform
  // property value that was updated
  nextState = {...nextState, transform: buildTransformString(nextState)}

  return nextState
}

export const svgSettings = (state, action) => {
  switch (action.type) {
    case actions.SET_IMAGE_SETTINGS:
      return {...state, imageSettings: action.payload}
    case actions.SET_EMBED_IMAGE:
      return {...state, embedImage: action.payload}
    case actions.SET_X:
      return {...state, x: action.payload}
    case actions.SET_Y:
      return {...state, y: action.payload}
    case actions.SET_WIDTH:
      return {...state, width: action.payload}
    case actions.SET_HEIGHT:
      return {...state, height: action.payload}
    case actions.SET_ERROR:
      return {...state, error: action.payload}
    case actions.SET_TRANSLATE_X:
      return nextStateForTransform(state, 'translateX', action.payload)
    case actions.SET_TRANSLATE_Y:
      return nextStateForTransform(state, 'translateY', action.payload)
    default:
      return {...state, ...action}
  }
}
