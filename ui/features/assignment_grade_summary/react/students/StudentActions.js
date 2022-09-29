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

import {addProvisionalGrades} from '../grades/GradeActions'
import * as StudentsApi from './StudentsApi'

export const ADD_STUDENTS = 'ADD_STUDENTS'
export const FAILURE = 'FAILURE'
export const SET_LOAD_STUDENTS_STATUS = 'SET_LOAD_STUDENTS_STATUS'
export const STARTED = 'STARTED'
export const SUCCESS = 'SUCCESS'

export function addStudents(students) {
  return {type: ADD_STUDENTS, payload: {students}}
}

export function setLoadStudentsStatus(status) {
  return {type: SET_LOAD_STUDENTS_STATUS, payload: {status}}
}

export function loadStudents() {
  return (dispatch, getState) => {
    const {assignment} = getState().assignment

    dispatch(setLoadStudentsStatus(STARTED))

    StudentsApi.loadStudents(assignment.courseId, assignment.id, {
      onAllPagesLoaded() {
        dispatch(setLoadStudentsStatus(SUCCESS))
      },
      onFailure() {
        dispatch(setLoadStudentsStatus(FAILURE))
      },
      onPageLoaded({provisionalGrades, students}) {
        dispatch(addStudents(students))
        dispatch(addProvisionalGrades(provisionalGrades))
      },
    })
  }
}
