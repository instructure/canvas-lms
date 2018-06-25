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
export const SET_UPDATE_GRADE_STATUS = 'SET_UPDATE_GRADE_STATUS'
export const STARTED = 'STARTED'
export const SUCCESS = 'SUCCESS'
export const UPDATE_GRADE = 'UPDATE_GRADE'

export function addProvisionalGrades(provisionalGrades) {
  return {type: ADD_PROVISIONAL_GRADES, payload: {provisionalGrades}}
}

export function setSelectProvisionalGradeStatus(gradeInfo, status) {
  return {type: SET_SELECT_PROVISIONAL_GRADE_STATUS, status, payload: {gradeInfo, status}}
}

export function setSelectedProvisionalGrade(gradeInfo) {
  return {type: SET_SELECTED_PROVISIONAL_GRADE, payload: {gradeInfo}}
}

export function setUpdateGradeStatus(gradeInfo, status) {
  return {type: SET_UPDATE_GRADE_STATUS, status, payload: {gradeInfo, status}}
}

export function updateGrade(gradeInfo) {
  return {type: UPDATE_GRADE, payload: {gradeInfo}}
}

function selectProvisionalGrade(gradeInfo) {
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

function apiUpdateProvisionalGrade(state, gradeInfo) {
  const {assignment} = state.assignment
  const {currentUser} = state.context
  const anonymous = !currentUser.canViewStudentIdentities
  const isFinalGrader = currentUser.id === assignment.finalGraderId

  const userIdField = anonymous ? 'anonymousId' : 'userId'

  const submission = {
    assignmentId: assignment.id,
    final: isFinalGrader,
    grade: gradeInfo.score,
    gradedAnonymously: anonymous,
    [userIdField]: gradeInfo.studentId
  }

  return GradesApi.updateProvisionalGrade(assignment.courseId, submission).then(
    updatedSubmission => ({
      ...gradeInfo,
      graderId: gradeInfo.graderId || currentUser.graderId,
      id: updatedSubmission.provisionalGradeId
    })
  )
}

function updateProvisionalGrade(gradeInfo) {
  return function(dispatch, getState) {
    const state = getState()

    dispatch(setUpdateGradeStatus(gradeInfo, STARTED))

    apiUpdateProvisionalGrade(state, gradeInfo)
      .then(updatedGradeInfo => {
        dispatch(updateGrade(updatedGradeInfo))
        dispatch(setUpdateGradeStatus(gradeInfo, SUCCESS))
      })
      .catch(() => {
        dispatch(setUpdateGradeStatus(gradeInfo, FAILURE))
      })
  }
}

function createAndSelectProvisionalGrade(gradeInfo) {
  return function(dispatch, getState) {
    const state = getState()

    dispatch(setUpdateGradeStatus(gradeInfo, STARTED))

    apiUpdateProvisionalGrade(state, gradeInfo)
      .then(updatedGradeInfo => {
        dispatch(updateGrade(updatedGradeInfo))
        dispatch(setUpdateGradeStatus(updatedGradeInfo, SUCCESS))
        dispatch(selectProvisionalGrade(updatedGradeInfo))
      })
      .catch(() => {
        dispatch(setUpdateGradeStatus(gradeInfo, FAILURE))
      })
  }
}

export function selectFinalGrade(gradeInfo) {
  if (gradeInfo.id == null) {
    return createAndSelectProvisionalGrade(gradeInfo)
  }

  if (gradeInfo.selected) {
    return updateProvisionalGrade(gradeInfo)
  }

  return selectProvisionalGrade(gradeInfo)
}
