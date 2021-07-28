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

import * as AssignmentApi from './AssignmentApi'

export const FAILURE = 'FAILURE'
export const GRADES_ALREADY_RELEASED = 'GRADES_ALREADY_RELEASED'
export const NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE = 'NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE'
export const SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS = 'SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS'
export const SET_RELEASE_GRADES_STATUS = 'SET_RELEASE_GRADES_STATUS'
export const SET_UNMUTE_ASSIGNMENT_STATUS = 'SET_UNMUTE_ASSIGNMENT_STATUS'
export const STARTED = 'STARTED'
export const SUCCESS = 'SUCCESS'
export const UPDATE_ASSIGNMENT = 'UPDATE_ASSIGNMENT'

export function setReleaseGradesStatus(status) {
  return {type: SET_RELEASE_GRADES_STATUS, payload: {status}}
}

export function setUnmuteAssignmentStatus(status) {
  return {type: SET_UNMUTE_ASSIGNMENT_STATUS, payload: {status}}
}

export function updateAssignment(assignment) {
  return {type: UPDATE_ASSIGNMENT, payload: {assignment}}
}

export function releaseGrades() {
  return function (dispatch, getState) {
    const {assignment} = getState().assignment

    dispatch(setReleaseGradesStatus(STARTED))

    AssignmentApi.releaseGrades(assignment.courseId, assignment.id)
      .then(() => {
        dispatch(updateAssignment({gradesPublished: true}))
        dispatch(setReleaseGradesStatus(SUCCESS))
      })
      .catch(({response}) => {
        switch (response.status) {
          case 400:
            dispatch(updateAssignment({gradesPublished: true}))
            dispatch(setReleaseGradesStatus(GRADES_ALREADY_RELEASED))
            break
          case 422:
            dispatch(setReleaseGradesStatus(NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE))
            break
          default:
            dispatch(setReleaseGradesStatus(FAILURE))
        }
      })
  }
}

export function unmuteAssignment() {
  return function (dispatch, getState) {
    const {assignment} = getState().assignment

    dispatch(setUnmuteAssignmentStatus(STARTED))

    AssignmentApi.unmuteAssignment(assignment.courseId, assignment.id)
      .then(() => {
        dispatch(updateAssignment({muted: false}))
        dispatch(setUnmuteAssignmentStatus(SUCCESS))
      })
      .catch(() => {
        dispatch(setUnmuteAssignmentStatus(FAILURE))
      })
  }
}
