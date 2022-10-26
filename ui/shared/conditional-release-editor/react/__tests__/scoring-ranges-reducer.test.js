/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import Path from '../assignment-path'
import reducer from '../scoring-ranges-reducer'
import * as actions from '../actions'

const saveData = data => {
  return {
    data: {
      scoring_ranges: data,
    },
  }
}

function reduce(state, type, payload) {
  return reducer(Immutable.fromJS(state), {type, payload})
}

function initialState() {
  return [
    {
      lower_bound: '0.8484',
      upper_bound: '1.00',
      assignment_sets: [{assignment_set_associations: []}],
    },
    {
      lower_bound: '0.4242',
      upper_bound: '0.8484',
      assignment_sets: [{assignment_set_associations: []}],
    },
    {
      lower_bound: '0',
      upper_bound: '0.4242',
      assignment_sets: [{assignment_set_associations: []}],
    },
  ]
}

describe('scoringRangeReducer', () => {
  it('returns an empty list by default', () => {
    expect(reducer()).toEqual(List())
  })

  it('loads default scoring ranges on get if none found', () => {
    const newState = reduce([], actions.LOAD_RULE_FOR_ASSIGNMENT, {data: null})
    expect(newState.size).toBe(3)
    expect(newState.getIn([3, 'upper_bound'])).not.toBe('42.42')
  })

  it('sets state on save', () => {
    const newState = reduce([], actions.SAVE_RULE, saveData(initialState()))
    expect(newState).toEqual(Immutable.fromJS(initialState()))
  })

  it('sorts ranges', () => {
    const newState = reduce(
      [],
      actions.SAVE_RULE,
      saveData([
        {lower_bound: '0.05', upper_bound: '0.10'},
        {lower_bound: '0.25', upper_bound: '0.30'},
        {lower_bound: '0.15', upper_bound: '0.20'},
      ])
    )
    expect(newState).toEqual(
      Immutable.fromJS([
        {lower_bound: '0.25', upper_bound: '0.30'},
        {lower_bound: '0.15', upper_bound: '0.20'},
        {lower_bound: '0.05', upper_bound: '0.10'},
      ])
    )
  })

  it('sets lower and upper bounds when boundary changes', () => {
    let newState = reduce(initialState(), actions.SET_SCORE_AT_INDEX, {index: 0, score: '0.60'})
    newState = newState.map(range =>
      Map({lower_bound: range.get('lower_bound'), upper_bound: range.get('upper_bound')})
    )
    expect(newState).toEqual(
      Immutable.fromJS([
        {lower_bound: '0.60', upper_bound: '1.00'},
        {lower_bound: '0.4242', upper_bound: '0.60'},
        {lower_bound: '0', upper_bound: '0.4242'},
      ])
    )
  })

  it('ignores setting boundaries on the last range', () => {
    let newState = reduce(initialState(), actions.SET_SCORE_AT_INDEX, {index: 2, score: '0.60'})
    newState = newState.map(range =>
      Map({lower_bound: range.get('lower_bound'), upper_bound: range.get('upper_bound')})
    )
    expect(newState).toEqual(
      Immutable.fromJS([
        {lower_bound: '0.8484', upper_bound: '1.00'},
        {lower_bound: '0.4242', upper_bound: '0.8484'},
        {lower_bound: '0', upper_bound: '0.4242'},
      ])
    )
  })

  it('allows setting bound to 0 on the middle range', () => {
    let newState = reduce(initialState(), actions.SET_SCORE_AT_INDEX, {index: 1, score: '0'})
    newState = newState.map(range =>
      Map({lower_bound: range.get('lower_bound'), upper_bound: range.get('upper_bound')})
    )
    expect(newState).toEqual(
      Immutable.fromJS([
        {lower_bound: '0.8484', upper_bound: '1.00'},
        {lower_bound: '0', upper_bound: '0.8484'},
        {lower_bound: '0', upper_bound: '0'},
      ])
    )
  })

  it('sets errors if present', () => {
    const newState = reduce(initialState(), actions.SET_ERROR_AT_SCORE_INDEX, {
      index: 0,
      error: 'rats',
    })
    expect(newState.getIn([0, 'error'])).toBe('rats')
  })

  it('adds items to scoring range assigment set', () => {
    const newState = reduce(initialState(), actions.ADD_ASSIGNMENTS_TO_RANGE_SET, {
      index: 0,
      assignmentSetIndex: 0,
      assignment_set_associations: [{assignment_id: 1}, {assignment_id: 2}],
    })
    expect(
      newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations', 0, 'assignment_id'])
    ).toBe(1)
    expect(
      newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations', 1, 'assignment_id'])
    ).toBe(2)
  })

  it('merges assignment sets together', () => {
    const state = initialState()
    state[0].assignment_sets = [
      {assignment_set_associations: [{assignment_id: '1'}]},
      {assignment_set_associations: [{assignment_id: '2'}]},
    ]

    const newState = reduce(state, actions.MERGE_ASSIGNMENT_SETS, {index: 0, leftSetIndex: 0})
    const newSets = newState.getIn([0, 'assignment_sets'])

    expect(newSets.size).toBe(1)
    expect(newSets.getIn([0, 'assignment_set_associations', 0, 'assignment_id'])).toBe('1')
    expect(newSets.getIn([0, 'assignment_set_associations', 1, 'assignment_id'])).toBe('2')
  })

  it('removes duplicates when merging assignment sets', () => {
    const state = initialState()
    state[0].assignment_sets = [
      {assignment_set_associations: [{assignment_id: '2'}, {assignment_id: '1'}]},
      {assignment_set_associations: [{assignment_id: '2'}]},
    ]

    const newState = reduce(state, actions.MERGE_ASSIGNMENT_SETS, {index: 0, leftSetIndex: 0})
    const newSets = newState.getIn([0, 'assignment_sets'])

    expect(newSets.size).toBe(1)
    expect(newSets.getIn([0, 'assignment_set_associations']).size).toBe(2)
    expect(newSets.getIn([0, 'assignment_set_associations', 0, 'assignment_id'])).toBe('2')
    expect(newSets.getIn([0, 'assignment_set_associations', 1, 'assignment_id'])).toBe('1')
  })

  it('removes cyoe assignment ids when merging assignment sets', () => {
    const state = initialState()
    state[0].assignment_sets = [
      {assignment_set_associations: [{assignment_id: '1', id: 5}]},
      {assignment_set_associations: [{assignment_id: '2', id: 3}]},
    ]

    const newState = reduce(state, actions.MERGE_ASSIGNMENT_SETS, {index: 0, leftSetIndex: 0})
    const newSets = newState.getIn([0, 'assignment_sets'])

    expect(newSets.size).toBe(1)
    expect(newSets.getIn([0, 'assignment_set_associations']).size).toBe(2)
    expect(newSets.getIn([0, 'assignment_set_associations', 1, 'id'])).toBe(undefined)
  })

  it('splits assignment sets apart', () => {
    const state = initialState()
    state[0].assignment_sets = [
      {assignment_set_associations: [{assignment_id: '1'}, {assignment_id: '2'}]},
    ]

    const newState = reduce(state, actions.SPLIT_ASSIGNMENT_SET, {
      index: 0,
      assignmentSetIndex: 0,
      splitIndex: 1,
    })
    const newSets = newState.getIn([0, 'assignment_sets'])

    expect(newSets.size).toBe(2)
    expect(newSets.getIn([0, 'assignment_set_associations', 0, 'assignment_id'])).toBe('1')
    expect(newSets.getIn([1, 'assignment_set_associations', 0, 'assignment_id'])).toBe('2')
  })

  it('removes cyoe assignment ids when splitting assignment sets apart', () => {
    const state = initialState()
    state[0].assignment_sets = [
      {
        assignment_set_associations: [
          {assignment_id: '1', id: 4},
          {assignment_id: '2', id: 3},
        ],
      },
    ]

    const newState = reduce(state, actions.SPLIT_ASSIGNMENT_SET, {
      index: 0,
      assignmentSetIndex: 0,
      splitIndex: 1,
    })
    const newSets = newState.getIn([0, 'assignment_sets'])

    expect(newSets.size).toBe(2)
    expect(newSets.getIn([1, 'assignment_set_associations', 0, 'id'])).toBe(undefined)
  })

  it('removes a single assignment from scoring range set', () => {
    const state = initialState()
    state[0].assignment_sets[0].assignment_set_associations.push({assignment_id: '1'})
    state[0].assignment_sets[0].assignment_set_associations.push({assignment_id: '2'})

    const newState = reduce(state, actions.REMOVE_ASSIGNMENT, {path: new Path(0, 0, 0)})
    expect(newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations']).size).toBe(1)
    expect(
      newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations', 0, 'assignment_id'])
    ).toBe('2')
  })

  it('updates assignment index', () => {
    const state = initialState()
    state[0].assignment_sets[0].assignment_set_associations.push({assignment_id: '1'})
    state[0].assignment_sets[0].assignment_set_associations.push({assignment_id: '2'})
    state[0].assignment_sets[0].assignment_set_associations.push({assignment_id: '3'})

    const newState = reduce(state, actions.UPDATE_ASSIGNMENT_INDEX, {
      path: new Path(0, 0, 2),
      assignmentIndex: 0,
    })

    expect(newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations']).size).toBe(3)
    expect(
      newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations', 0, 'assignment_id'])
    ).toBe('1')
    expect(
      newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations', 1, 'assignment_id'])
    ).toBe('3')
    expect(
      newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations', 2, 'assignment_id'])
    ).toBe('2')
  })

  it('inserts assignment at index', () => {
    const state = initialState()
    state[0].assignment_sets[0].assignment_set_associations.push({assignment_id: '1'})
    state[0].assignment_sets[0].assignment_set_associations.push({assignment_id: '2'})

    const newState = reduce(state, actions.INSERT_ASSIGNMENT, {
      path: new Path(0, 0, 0),
      assignment: '3',
    })

    expect(newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations']).size).toBe(3)
    expect(
      newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations', 0, 'assignment_id'])
    ).toBe('1')
    expect(
      newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations', 1, 'assignment_id'])
    ).toBe('3')
    expect(
      newState.getIn([0, 'assignment_sets', 0, 'assignment_set_associations', 2, 'assignment_id'])
    ).toBe('2')
  })
})
