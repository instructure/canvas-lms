/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {createAction} from 'redux-actions'
import * as validations from './validations'
import GradingTypes from './grading-types'

import CyoeApi from './cyoe-api'
import * as AssignmentPickerActions from './assignment-picker-actions'

export const SET_BASE_URL = 'SET_BASE_URL'
export const setBaseUrl = createAction(SET_BASE_URL)

export const SET_COURSE_ID = 'SET_COURSE_ID'
export const setCourseId = createAction(SET_COURSE_ID)

export const SET_ARIA_ALERT = 'SET_ARIA_ALERT'
export const setAriaAlert = createAction(SET_ARIA_ALERT)

export const CLEAR_ARIA_ALERT = 'CLEAR_ARIA_ALERT'
export const clearAriaAlert = createAction(CLEAR_ARIA_ALERT)

export const SET_GLOBAL_WARNING = 'SET_GLOBAL_WARNING'
export const setGlobalWarning = createAction(SET_GLOBAL_WARNING)

export const CLEAR_GLOBAL_WARNING = 'CLEAR_GLOBAL_WARNING'
export const clearGlobalWarning = createAction(CLEAR_GLOBAL_WARNING)

export const LOAD_DEFAULT_RULE = 'LOAD_DEFAULT_RULE'
export const loadDefaultRule = createAction(LOAD_DEFAULT_RULE)

export const LOAD_RULE_FOR_ASSIGNMENT = 'LOAD_RULE_FOR_ASSIGNMENT'
export const loadRuleForAssignment = createAction(LOAD_RULE_FOR_ASSIGNMENT, state =>
  CyoeApi.getRuleForAssignment(state)
)

export const SET_SCORE_AT_INDEX = 'SET_SCORE_AT_INDEX'
export const setScoreAtIndex = (index, score) => {
  return (dispatch, _getState) => {
    // even erroneous input should be reflected in the interface
    dispatch(setScoreAtIndexFrd(index, score))
    dispatch(validateScores(true))
  }
}

const setScoreAtIndexFrd = createAction(SET_SCORE_AT_INDEX, (index, score) => ({index, score}))

export const UPDATE_ASSIGNMENT = 'UPDATE_ASSIGNMENT'
export const updateAssignment = assignment => {
  return (dispatch, _getState) => {
    dispatch(updateAssignmentFrd(assignment))

    // ensure letter grades don't have inexplicable 'number out of range' errors
    if (
      assignment.grading_type === GradingTypes.letter_grade.key ||
      assignment.grading_type === GradingTypes.gpa_scale.key
    ) {
      dispatch(clearOutOfRangeScores)
    }

    dispatch(validateScores(false))
  }
}

const updateAssignmentFrd = createAction(UPDATE_ASSIGNMENT)

const getScores = state => {
  const allScores = state.getIn(['rule', 'scoring_ranges']).map(s => s.get('lower_bound'))
  return allScores.pop() // last score will always be null
}

const validateScores = notifyOnError => {
  return (dispatch, getState) => {
    const scoringInfo = getState().get('trigger_assignment')
    const scores = getScores(getState())

    const errors = validations.validateScores(scores, scoringInfo)

    errors.forEach((error, errorIndex) => {
      if (notifyOnError) {
        const currentError = getState().getIn(['rule', 'scoring_ranges', errorIndex, 'error'])
        if (error && error !== currentError) {
          dispatch(setAriaAlert(error))
        }
      }
      dispatch(setErrorAtScoreIndex(errorIndex, error))
    })
  }
}

const clearOutOfRangeScores = (dispatch, getState) => {
  const scores = getScores(getState())
  scores.forEach((score, index) => {
    if (score < 0 || score > 1) {
      dispatch(setScoreAtIndexFrd(index, ''))
    }
  })
}

export const SET_ERROR_AT_SCORE_INDEX = 'SET_ERROR_AT_SCORE_INDEX'
export const setErrorAtScoreIndex = createAction(SET_ERROR_AT_SCORE_INDEX, (index, error) => ({
  index,
  error,
}))

// Creates, saves, or deletes rule depending on current state
// Returns a promise
export const commitRule = state => {
  const trigger = state.getIn(['trigger_assignment', 'id'])
  const ruleId = state.getIn(['rule', 'id'])
  if (trigger) {
    return saveRule(state)
  } else if (ruleId) {
    return deleteRule(state)
  } else {
    return createAction('NO_OP', s => Promise.resolve(s))(state)
  }
}

export const SAVE_RULE = 'SAVE_RULE'
export const saveRule = createAction(SAVE_RULE, state => CyoeApi.saveRule(state))

export const DELETE_RULE = 'DELETE_RULE'
export const deleteRule = createAction(DELETE_RULE, state => CyoeApi.deleteRule(state))

// @payload: index: scoring range index to remove assignment from
//           assignmentSetIndex: index of assignment set to remove assignment from
//           assignment: canvas id of assignment to remove
export const REMOVE_ASSIGNMENT = 'REMOVE_ASSIGNMENT'
export const removeAssignment = createAction(REMOVE_ASSIGNMENT)

// @payload: store state (requires courseId in state)
export const GET_ASSIGNMENTS = 'GET_ASSIGNMENTS'
export const getAssignments = createAction(GET_ASSIGNMENTS, state => CyoeApi.getAssignments(state))

// @payload: list of assignment instances
export const ADD_ASSIGNMENTS_TO_RANGE_SET = 'ADD_ASSIGNMENTS_TO_RANGE_SET'
export const addAssignmentsToRangeSet = createAction(ADD_ASSIGNMENTS_TO_RANGE_SET)

// @payload: path: path object of where to insert assignment
//           assignment: canvas assignment id of assignment to be inserted
export const INSERT_ASSIGNMENT = 'INSERT_ASSIGNMENT'
export const insertAssignment = createAction(INSERT_ASSIGNMENT)

// @payload: path: current assignment path
//           index: new assignment index
export const UPDATE_ASSIGNMENT_INDEX = 'UPDATE_ASSIGNMENT_INDEX'
export const updateAssignmentIndex = createAction(UPDATE_ASSIGNMENT_INDEX)

// @payload: oldPath: current path of assignment to be moved
//           newPath: path to move the assignment to
//           assignment: assignment id of assignment being moved
export const moveAssignment = (oldPath, newPath, assignment) => {
  return dispatch => {
    if (oldPath.range === newPath.range && oldPath.set === newPath.set) {
      dispatch(updateAssignmentIndex({path: oldPath, assignmentIndex: newPath.assignment}))
    } else {
      dispatch(
        insertAssignment({
          path: newPath,
          assignment,
        })
      )

      dispatch(removeAssignment({path: oldPath}))
    }
  }
}

// @payload: leftSetIndex: index in the left set to be merged with the right set
export const MERGE_ASSIGNMENT_SETS = 'MERGE_ASSIGNMENT_SETS'
export const mergeAssignmentSets = createAction(MERGE_ASSIGNMENT_SETS)

// @payload: assignmentSetIndex: index of the set in scoring range
//           splitIndex: the assignment index where to split the set
export const SPLIT_ASSIGNMENT_SET = 'SPLIT_ASSIGNMENT_SET'
export const splitAssignmentSet = createAction(SPLIT_ASSIGNMENT_SET)

// @payload: list of assignment instances
export const assignmentPicker = AssignmentPickerActions
