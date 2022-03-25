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

import {StoreState, OriginalState, CoursePace} from '../types'
import {Constants as CoursePaceConstants} from '../actions/course_paces'
import {Constants as UIConstants} from '../actions/ui'

export const initialState: OriginalState = {
  coursePace: window.ENV.COURSE_PACE
}

/* Selectors */

export const getOriginalPace = (state: StoreState): CoursePace => state.original.coursePace

/* Reducers */

export const originalReducer = (state = initialState, action: any): OriginalState => {
  switch (action.type) {
    case CoursePaceConstants.COURSE_PACE_SAVED:
      return {...state, coursePace: action.payload}
    case UIConstants.SET_SELECTED_PACE_CONTEXT:
      return {...state, coursePace: action.payload.newSelectedPace}
    default:
      return state
  }
}
