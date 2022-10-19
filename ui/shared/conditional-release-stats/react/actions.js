/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import cyoeClient from './cyoe-api'
import {createActions} from './helpers/actions'

const actionDefs = [
  'SET_INITIAL_DATA',
  'SET_SCORING_RANGES',
  'SET_RULE',
  'SET_ENROLLED',
  'SET_ASSIGNMENT',
  'SET_ERRORS',
  'SET_STUDENT_DETAILS',
  'SELECT_RANGE',
  'ADD_STUDENT_TO_CACHE',
  'SELECT_STUDENT',
  'OPEN_SIDEBAR',
  'CLOSE_SIDEBAR',
  'LOAD_INITIAL_DATA_START',
  'LOAD_INITIAL_DATA_END',
  'LOAD_STUDENT_DETAILS_START',
  'LOAD_STUDENT_DETAILS_END',
]

export const {actions, actionTypes} = createActions(actionDefs)

actions.closeSidebarFrd = actions.closeSidebar

actions.closeSidebar = () => {
  return (dispatch, getState) => {
    const sidebarTrigger = getState().sidebarTrigger
    dispatch(actions.closeSidebarFrd())
    sidebarTrigger.focus()
  }
}

actions.loadInitialData = _assignment => {
  return (dispatch, getState) => {
    dispatch(actions.loadInitialDataStart())

    cyoeClient
      .loadInitialData(getState())
      .then(data => {
        dispatch(actions.setInitialData(data))
        dispatch(actions.loadInitialDataEnd())
      })
      .catch(errors => {
        dispatch(actions.setErrors(errors))
        dispatch(actions.loadInitialDataEnd())
      })
  }
}

actions.loadStudent = studentId => {
  return (dispatch, getState) => {
    dispatch(actions.loadStudentDetailsStart())

    cyoeClient
      .loadStudent(getState(), studentId)
      .then(data => {
        dispatch(actions.addStudentToCache({studentId, data}))
        dispatch(actions.loadStudentDetailsEnd())
      })
      .catch(errors => {
        dispatch(actions.loadStudentDetailsEnd())
        dispatch(actions.setErrors(errors))
      })
  }
}

actions.selectStudent = studentIndex => {
  return (dispatch, getState) => {
    dispatch({type: actionTypes.SELECT_STUDENT, payload: studentIndex})

    const {studentCache, ranges, selectedPath} = getState()

    const student = ranges[selectedPath.range].students[studentIndex]

    if (student && !studentCache[student.user.id.toString()]) {
      dispatch(actions.loadStudent(student.user.id.toString()))
    }
  }
}
