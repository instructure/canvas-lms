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

import Actions from 'ui/features/assignment_index/react/actions/IndexMenuActions'
import Reducer from 'ui/features/assignment_index/react/reducers/indexMenuReducer'

QUnit.module('AssignmentsIndexMenuReducer')

test('SET_MODAL_OPEN actions result in expected state', () => {
  const initialState1 = {modalIsOpen: false}
  const action1 = {
    type: Actions.SET_MODAL_OPEN,
    payload: true,
  }
  const expectedState1 = {modalIsOpen: true}
  const newState1 = Reducer(initialState1, action1)
  deepEqual(expectedState1, newState1)

  const initialState2 = {modalIsOpen: true}
  const action2 = {
    type: Actions.SET_MODAL_OPEN,
    payload: false,
  }
  const expectedState2 = {modalIsOpen: false}
  const newState2 = Reducer(initialState2, action2)
  deepEqual(expectedState2, newState2)
})

test('LAUNCH_TOOL actions result in expected state', () => {
  const tool = {foo: 'bar'}
  const initialState = {modalIsOpen: false, selectedTool: null}
  const action = {type: Actions.LAUNCH_TOOL, payload: tool}
  const expectedState = {modalIsOpen: true, selectedTool: tool}
  const newState = Reducer(initialState, action)

  deepEqual(expectedState, newState)
})

test('SET_TOOLS actions result in expected state', () => {
  const tools = [1, 2, 3]
  const initialState = {externalTools: []}
  const action = {type: Actions.SET_TOOLS, payload: tools}
  const expectedState = {externalTools: tools}
  const newState = Reducer(initialState, action)

  deepEqual(expectedState, newState)
})

test('SET_WEIGHTED actions result in expected state', () => {
  const initialState1 = {weighted: false}
  const action1 = {
    type: Actions.SET_WEIGHTED,
    payload: true,
  }
  const expectedState1 = {weighted: true}
  const newState1 = Reducer(initialState1, action1)
  deepEqual(expectedState1, newState1)

  const initialState2 = {weighted: true}
  const action2 = {
    type: Actions.SET_WEIGHTED,
    payload: false,
  }
  const expectedState2 = {weighted: false}
  const newState2 = Reducer(initialState2, action2)
  deepEqual(expectedState2, newState2)
})
