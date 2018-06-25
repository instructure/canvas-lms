/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {applyMiddleware, combineReducers, createStore} from 'redux'
import ReduxThunk from 'redux-thunk'

import buildAssignmentReducer from './assignment/buildAssignmentReducer'
import gradesReducer from './grades/gradesReducer'
import studentsReducer from './students/studentsReducer'

const createStoreWithMiddleware = applyMiddleware(ReduxThunk)(createStore)

export default function configureStore(env) {
  const contextReducer = state =>
    state || {
      currentUser: env.currentUser,
      finalGrader: env.finalGrader,
      graders: env.graders
    }

  const reducer = combineReducers({
    assignment: buildAssignmentReducer(env),
    context: contextReducer,
    grades: gradesReducer,
    students: studentsReducer
  })

  return createStoreWithMiddleware(reducer)
}
