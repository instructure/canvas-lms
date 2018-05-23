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

import buildReducer from '../buildReducer'
import {ADD_STUDENTS, SET_LOAD_STUDENTS_STATUS} from './StudentActions'

function addStudents(state, students) {
  return {...state, list: [...state.list, ...students]}
}

function setLoadStudentsStatus(state, loadStudentsStatus) {
  return {...state, loadStudentsStatus}
}

const handlers = {}

handlers[ADD_STUDENTS] = (state, {payload}) => addStudents(state, payload.students)

handlers[SET_LOAD_STUDENTS_STATUS] = (state, {payload}) =>
  setLoadStudentsStatus(state, payload.status)

export default buildReducer(handlers, {
  list: [],
  loadStudentsStatus: null
})
