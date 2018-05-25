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

import * as GradesApi from './GradesApi'

export const ADD_PROVISIONAL_GRADES = 'ADD_PROVISIONAL_GRADES'
export const FAILURE = 'FAILURE'
export const SET_SELECTED_PROVISIONAL_GRADE = 'SET_SELECTED_PROVISIONAL_GRADE'
export const SET_SELECT_PROVISIONAL_GRADE_STATUS = 'SET_SELECT_PROVISIONAL_GRADE_STATUS'
export const STARTED = 'STARTED'
export const SUCCESS = 'SUCCESS'

export function addProvisionalGrades(provisionalGrades) {
  return {type: ADD_PROVISIONAL_GRADES, payload: {provisionalGrades}}
}

export function setSelectProvisionalGradeStatus(gradeInfo, status) {
  return {type: SET_SELECT_PROVISIONAL_GRADE_STATUS, status, payload: {gradeInfo, status}}
}

export function setSelectedProvisionalGrade(gradeInfo) {
  return {type: SET_SELECTED_PROVISIONAL_GRADE, payload: {gradeInfo}}
}

export function selectProvisionalGrade(gradeInfo) {
  return function(dispatch, getState) {
    const {assignment} = getState().assignment

    dispatch(setSelectProvisionalGradeStatus(gradeInfo, STARTED))

    GradesApi.selectProvisionalGrade(assignment.courseId, assignment.id, gradeInfo.id)
      .then(() => {
        dispatch(setSelectedProvisionalGrade(gradeInfo))
        dispatch(setSelectProvisionalGradeStatus(gradeInfo, SUCCESS))
      })
      .catch(() => {
        dispatch(setSelectProvisionalGradeStatus(gradeInfo, FAILURE))
      })
  }
}
