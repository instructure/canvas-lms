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

import {combineReducers} from 'redux'

import type {StoreState} from '../types'
import coursePacesReducer from './course_paces'
import {courseReducer} from './course'
import {sectionsReducer} from './sections'
import {enrollmentsReducer} from './enrollments'
import {blackoutDatesReducer} from '../shared/reducers/blackout_dates'
import {originalReducer} from './original'
import uiReducer from './ui'
import {paceContextsReducer} from './pace_contexts'

export default combineReducers<StoreState>({
  coursePace: coursePacesReducer,
  enrollments: enrollmentsReducer,
  sections: sectionsReducer,
  ui: uiReducer,
  course: courseReducer,
  blackoutDates: blackoutDatesReducer,
  original: originalReducer,
  paceContexts: paceContextsReducer,
})
