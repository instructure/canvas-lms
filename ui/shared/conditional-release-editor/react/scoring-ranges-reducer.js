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

import Immutable, {List, Map} from 'immutable'
import {combineReducers} from 'redux-immutable'
import {handleActions} from 'redux-actions'
import * as actions from './actions'
import {onSuccessOnly} from './reducer-helpers'

const DEFAULT_SCORING_RANGES = Immutable.fromJS([
  {upper_bound: null, lower_bound: 0.7, assignment_sets: [{assignment_set_associations: []}]},
  {upper_bound: 0.7, lower_bound: 0.4, assignment_sets: [{assignment_set_associations: []}]},
  {upper_bound: 0.4, lower_bound: null, assignment_sets: [{assignment_set_associations: []}]},
])

const emptyAssignmentSet = () => Map({assignment_set_associations: List()})

const identity =
  (dflt = '') =>
  (s, _a) =>
    s == null ? dflt : s

const scoringRangesReducer = (state, action) => {
  if (state === undefined) return List()
  state = overallScoringRangesReducer(state, action)

  // temporary hack until all actions switch over to Path()
  const rangeIndex = action.payload
    ? action.payload.index !== undefined
      ? action.payload.index
      : action.payload.path && action.payload.path.range
    : undefined

  if (rangeIndex !== undefined) {
    const selectedScoringRange = state.get(rangeIndex)
    if (selectedScoringRange) {
      const newScoringRange = structuredSingleScoringRangeReducer(selectedScoringRange, action)
      state = state.set(rangeIndex, newScoringRange)
    }
  }

  return state
}
export default scoringRangesReducer

const sortRanges = ranges => {
  return ranges.sort((a, b) => b.get('lower_bound') - a.get('lower_bound'))
}

const getDefaultScoringRanges = (_state, _action) => DEFAULT_SCORING_RANGES

const gotRuleSetScoringRanges = onSuccessOnly((state, action) => {
  if (!action.payload.data) return DEFAULT_SCORING_RANGES
  const ranges = Immutable.fromJS(action.payload.data.scoring_ranges).map(range => {
    if (!range.has('assignment_sets') || range.get('assignment_sets').size === 0) {
      range = range.set('assignment_sets', List([emptyAssignmentSet()]))
    }

    return range
  })

  return sortRanges(ranges)
})

const savedRuleSetScoringRanges = onSuccessOnly((state, action) => {
  const ranges = Immutable.fromJS(action.payload.data.scoring_ranges)
  return sortRanges(ranges)
})

const juggleBounds = (state, action) => {
  if (action.payload.index === undefined) return state
  // the last range's lower bound can't be set
  if (action.payload.index >= state.size - 1) return state
  if (action.payload.index < 0) return state
  state = state.setIn([action.payload.index, 'lower_bound'], action.payload.score)
  state = state.setIn([action.payload.index + 1, 'upper_bound'], action.payload.score)
  return state
}

const addAssignments = (state, action) => {
  const assignments = action.payload.assignment_set_associations

  return state.concat(
    // check if assignments are immutable, otherwise convert them to immutable
    Immutable.Iterable.isIterable(assignments) ? assignments : Immutable.fromJS(assignments)
  )
}

const removeAssignment = (state, action) => {
  return state.delete(action.payload.path.assignment)
}

const insertAssignment = (state, action) => {
  const assignment = action.payload.path.assignment
  return state.insert(
    assignment !== undefined ? assignment + 1 : state.size,
    Map({assignment_id: action.payload.assignment})
  )
}

const updateAssignmentIndex = (state, action) => {
  const oldIndex = action.payload.path.assignment
  const newIndex = action.payload.assignmentIndex
  const assg = state.get(oldIndex)

  return state.delete(oldIndex).insert(newIndex + (newIndex > oldIndex ? 0 : 1), assg)
}

const mergeAssignmentSets = (state, action) => {
  const leftIndex = action.payload.leftSetIndex
  const rightIndex = leftIndex + 1

  state = state.updateIn([leftIndex, 'assignment_set_associations'], assignments => {
    const newAssignments = state.getIn([rightIndex, 'assignment_set_associations'], List())

    newAssignments.forEach(newAssg => {
      const isFound = assignments.find(
        assg => assg.get('assignment_id') === newAssg.get('assignment_id')
      )
      if (!isFound) assignments = assignments.push(newAssg.delete('id'))
    })

    return assignments
  })

  state = state.delete(rightIndex)

  return state
}

const splitAssignmentSet = (state, action) => {
  const assignmentSetIndex = action.payload.assignmentSetIndex
  const splitIndex = action.payload.splitIndex

  const assignments = state.getIn([assignmentSetIndex, 'assignment_set_associations'])

  state = state.updateIn([assignmentSetIndex, 'assignment_set_associations'], assmts => {
    return assmts.slice(0, splitIndex)
  })

  state = state.insert(
    assignmentSetIndex + 1,
    Map({
      assignment_set_associations: assignments.slice(splitIndex).map(assg => assg.delete('id')),
    })
  )

  return state
}

const removeDuplicatesFromSet = set => {
  return set.update('assignment_set_associations', assgs => {
    const seenIds = []
    return assgs.filter(asg => {
      if (seenIds.indexOf(asg.get('assignment_id')) === -1) {
        seenIds.push(asg.get('assignment_id'))
        return true
      } else {
        return false
      }
    })
  })
}

export const removeEmptySets = sets => {
  sets = sets.filter(set => {
    return set.get('assignment_set_associations').size !== 0
  })

  // make sure there's always at least one set
  if (sets.size === 0) {
    sets = sets.push(emptyAssignmentSet())
  }

  return sets
}

const assignmentSetReducer = (state, action) => {
  state = overallAssignmentSetReducer(state, action)

  // temporary hack until all actions switch over to Path()
  const setIndex =
    action.payload.assignmentSetIndex !== undefined
      ? action.payload.assignmentSetIndex
      : action.payload.path && action.payload.path.set

  if (setIndex !== undefined) {
    const selectedAssignmentSet = state.get(setIndex)
    if (selectedAssignmentSet) {
      const newAssignmentSet = singleAssignmentSetReducer(selectedAssignmentSet, action)
      state = state.set(setIndex, newAssignmentSet)
    }
  }

  state = state.map(removeDuplicatesFromSet)
  state = removeEmptySets(state)

  return state
}

const overallAssignmentSetReducer = handleActions(
  {
    [actions.MERGE_ASSIGNMENT_SETS]: mergeAssignmentSets,
    [actions.SPLIT_ASSIGNMENT_SET]: splitAssignmentSet,
  },
  List(emptyAssignmentSet())
)

const singleAssignmentSetReducer = combineReducers({
  id: identity(null),
  created_at: identity(),
  updated_at: identity(),
  scoring_range_id: identity(),
  position: identity(null),

  assignment_set_associations: handleActions(
    {
      [actions.ADD_ASSIGNMENTS_TO_RANGE_SET]: addAssignments,
      [actions.REMOVE_ASSIGNMENT]: removeAssignment,
      [actions.INSERT_ASSIGNMENT]: insertAssignment,
      [actions.UPDATE_ASSIGNMENT_INDEX]: updateAssignmentIndex,
    },
    List()
  ),
})

const overallScoringRangesReducer = handleActions(
  {
    [actions.LOAD_RULE_FOR_ASSIGNMENT]: gotRuleSetScoringRanges,
    [actions.LOAD_DEFAULT_RULE]: getDefaultScoringRanges,
    [actions.SAVE_RULE]: savedRuleSetScoringRanges,
    [actions.SET_SCORE_AT_INDEX]: juggleBounds,
  },
  List()
)

const structuredSingleScoringRangeReducer = combineReducers({
  error: handleActions(
    {
      [actions.SET_ERROR_AT_SCORE_INDEX]: (_s, a) => a.payload.error,
    },
    ''
  ),

  assignment_sets: assignmentSetReducer,

  // prevent warnings from combineReducers about unexpected properties.
  lower_bound: identity(),
  upper_bound: identity(),
  created_at: identity(),
  updated_at: identity(),
  id: identity(),
  rule_id: identity(),
  position: identity(null),
})
