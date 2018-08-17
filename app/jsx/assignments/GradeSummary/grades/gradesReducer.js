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

import {buildReducer, updateIn} from '../ReducerHelpers'
import {
  ADD_PROVISIONAL_GRADES,
  SET_SELECTED_PROVISIONAL_GRADE,
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

function setSelectedProvisionalGrade(state, gradeInfo) {
  const provisionalGrades = {...state.grades.provisionalGrades}
  const studentGrades = {...provisionalGrades[gradeInfo.studentId]}
  Object.keys(studentGrades).forEach(graderId => {
    if (studentGrades[graderId].selected) {
      studentGrades[graderId] = {...studentGrades[graderId], selected: false}
    }
  })
  studentGrades[gradeInfo.graderId] = {...gradeInfo, selected: true}
  provisionalGrades[gradeInfo.studentId] = studentGrades
  return updateIn(state, 'grades', {provisionalGrades})
}

function setSelectProvisionalGradeStatus(state, gradeInfo, status) {
  const selectProvisionalGradeStatuses = {...state.grades.selectProvisionalGradeStatuses}
  selectProvisionalGradeStatuses[gradeInfo.studentId] = status
  return updateIn(state, 'grades', {selectProvisionalGradeStatuses})
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

const handlers = {}

handlers[ADD_PROVISIONAL_GRADES] = (state, {payload}) =>
  addProvisionalGrades(state, payload.provisionalGrades)

handlers[SET_SELECTED_PROVISIONAL_GRADE] = (state, {payload}) =>
  setSelectedProvisionalGrade(state, payload.gradeInfo)

handlers[SET_SELECT_PROVISIONAL_GRADE_STATUS] = (state, {payload}) =>
  setSelectProvisionalGradeStatus(state, payload.gradeInfo, payload.status)

handlers[SET_UPDATE_GRADE_STATUS] = (state, {payload}) =>
  setUpdateGradeStatus(state, payload.gradeInfo, payload.status)

handlers[UPDATE_GRADE] = (state, {payload}) => addProvisionalGrades(state, [payload.gradeInfo])

export default buildReducer(handlers, {
  grades: {
    provisionalGrades: {},
    selectProvisionalGradeStatuses: {},
    updateGradeStatuses: []
  }
})
