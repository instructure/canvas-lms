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

import type {StoreState} from '../types'
import type {Course} from '../shared/types'

export const courseInitialState: Course = (window.ENV.COURSE || {}) as Course

/* Selectors */

export const getCourse = (state: StoreState): Course => state.course

/* Reducers */

export const courseReducer = (state = courseInitialState, action: any): Course => {
  switch (action.type) {
    default:
      return state
  }
}
