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

import {buildReducer, pipeState, updateIn} from '../ReducerHelpers'
import {
  ADD_PROVISIONAL_GRADES,
  SET_BULK_SELECT_PROVISIONAL_GRADE_STATUS,
  SET_SELECTED_PROVISIONAL_GRADE,
  SET_SELECTED_PROVISIONAL_GRADES,
  SET_SELECT_PROVISIONAL_GRADE_STATUS,
  SET_UPDATE_GRADE_STATUS,
  SUCCESS,
  UPDATE_GRADE
} from './GradeActions'

function addProvisionalGrades(state, grades) {
  const provisionalGrades = {...state.grades.provisionalGrades}
  grades.forEach(grade => {
    provisionalGrades[grade.studentId] = provisionalGrades[grade.studentId] || {}
    provisionalGrades[grade.studentId][grade.graderId] = grade
  })
  return updateIn(state, 'grades', {provisionalGrades})
}

function selectGradeInProvisionalGrades(gradeInfo, provisionalGrades) {
  const studentGrades = {...provisionalGrades[gradeInfo.studentId]}
  Object.keys(studentGrades).forEach(graderId => {
    if (studentGrades[graderId].selected) {
      studentGrades[graderId] = {...studentGrades[graderId], selected: false}
    }
  })
  studentGrades[gradeInfo.graderId] = {...gradeInfo, selected: true}
  provisionalGrades[gradeInfo.studentId] = studentGrades // eslint-disable-line no-param-reassign
}

function setSelectedProvisionalGrade(state, gradeInfo) {
  const provisionalGrades = {...state.grades.provisionalGrades}
  selectGradeInProvisionalGrades(gradeInfo, provisionalGrades)
  return updateIn(state, 'grades', {provisionalGrades})
}

function setSelectedProvisionalGrades(state, provisionalGradeIds) {
  const provisionalGrades = {...state.grades.provisionalGrades}
  const provisionalGradesById = {}

  Object.values(provisionalGrades).forEach(studentGradesMap => {
    Object.values(studentGradesMap).forEach(grade => {
      provisionalGradesById[grade.id] = grade
    })
  })

  provisionalGradeIds.forEach(gradeId => {
    const gradeInfo = provisionalGradesById[gradeId]
    selectGradeInProvisionalGrades(gradeInfo, provisionalGrades)
  })

  return updateIn(state, 'grades', {provisionalGrades})
}

function setSelectProvisionalGradeStatus(state, gradeInfo, status) {
  const selectProvisionalGradeStatuses = {...state.grades.selectProvisionalGradeStatuses}
  selectProvisionalGradeStatuses[gradeInfo.studentId] = status
  return updateIn(state, 'grades', {selectProvisionalGradeStatuses})
}

function setBulkSelectProvisionalGradeStatus(state, graderId, status) {
  const bulkSelectProvisionalGradeStatuses = {...state.grades.bulkSelectProvisionalGradeStatuses}
  bulkSelectProvisionalGradeStatuses[graderId] = status
  return updateIn(state, 'grades', {bulkSelectProvisionalGradeStatuses})
}

function setUpdateGradeStatus(state, gradeInfo, status) {
  const statuses = state.grades.updateGradeStatuses.filter(
    updateGradeStatus =>
      // Remove existing items for the same student or for previous successes.
      updateGradeStatus.gradeInfo.studentId !== gradeInfo.studentId && status !== SUCCESS
  )
  const updateGradeStatuses = statuses.concat([{gradeInfo, status}])
  return updateIn(state, 'grades', {updateGradeStatuses})
}

function provisionalGraderIdsFromGrades(studentGradesMap, graders) {
  const ids = []
  for (let i = 0; i < graders.length; i++) {
    if (graders[i].graderId in studentGradesMap) {
      ids.push(graders[i].graderId)
    }
  }
  return ids
}

function updateBulkSelectionDetails(state) {
  const {graders} = state.context
  const {provisionalGrades} = state.grades

  const bulkSelectionDetails = {}

  graders.forEach(({graderId}) => {
    bulkSelectionDetails[graderId] = {
      allowed: true,
      provisionalGradeIds: []
    }
  })

  Object.keys(provisionalGrades).forEach(studentId => {
    const studentGradesMap = provisionalGrades[studentId]
    const graderIds = provisionalGraderIdsFromGrades(studentGradesMap, graders)

    if (graderIds.length > 1) {
      graderIds.forEach(graderId => {
        bulkSelectionDetails[graderId] = {
          allowed: false,
          provisionalGradeIds: []
        }
      })
    } else if (!Object.values(studentGradesMap).some(grade => grade.selected)) {
      graderIds.forEach(graderId => {
        const grade = studentGradesMap[graderId]
        const details = bulkSelectionDetails[graderId]
        if (details.allowed) {
          details.provisionalGradeIds.push(grade.id)
        }
      })
    }
  })

  return updateIn(state, 'grades', {bulkSelectionDetails})
}

const handlers = {}

handlers[ADD_PROVISIONAL_GRADES] = (currentState, {payload}) =>
  pipeState(
    currentState,
    state => addProvisionalGrades(state, payload.provisionalGrades.filter(pg => pg.grade !== null)),
    state => updateBulkSelectionDetails(state)
  )

handlers[SET_SELECTED_PROVISIONAL_GRADE] = (currentState, {payload}) =>
  pipeState(
    currentState,
    state => setSelectedProvisionalGrade(state, payload.gradeInfo),
    state => updateBulkSelectionDetails(state)
  )

handlers[SET_SELECTED_PROVISIONAL_GRADES] = (currentState, {payload}) =>
  pipeState(
    currentState,
    state => setSelectedProvisionalGrades(state, payload.provisionalGradeIds),
    state => updateBulkSelectionDetails(state)
  )

handlers[SET_SELECT_PROVISIONAL_GRADE_STATUS] = (state, {payload}) =>
  setSelectProvisionalGradeStatus(state, payload.gradeInfo, payload.status)

handlers[SET_BULK_SELECT_PROVISIONAL_GRADE_STATUS] = (state, {payload}) =>
  setBulkSelectProvisionalGradeStatus(state, payload.graderId, payload.status)

handlers[SET_UPDATE_GRADE_STATUS] = (state, {payload}) =>
  setUpdateGradeStatus(state, payload.gradeInfo, payload.status)

handlers[UPDATE_GRADE] = (state, {payload}) => addProvisionalGrades(state, [payload.gradeInfo])

export default buildReducer(handlers, {
  grades: {
    bulkSelectProvisionalGradeStatuses: {},
    bulkSelectionDetails: {},
    provisionalGrades: {},
    selectProvisionalGradeStatuses: {},
    updateGradeStatuses: []
  }
})
