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

import {createAction, createActions} from '@canvas/conditional-release-stats/react/helpers/actions'

QUnit.module('Conditional Release Stats action helpers')

test('creates a new action', () => {
  const actionCreator = createAction('ACTION_ONE')
  const action = actionCreator('payload')

  equal(action.type, 'ACTION_ONE', 'action type match')
  equal(action.payload, 'payload', 'action payload match')
})

test('creates multiple actions', () => {
  const actionDefs = ['ACTION_ONE', 'ANOTHER_MORE_COMPLEX_ACTION_NAME']
  const {actionTypes, actions} = createActions(actionDefs)

  equal(actions.actionOne.type, 'ACTION_ONE')
  equal(actionTypes.ACTION_ONE, 'ACTION_ONE')
  equal(actions.anotherMoreComplexActionName.type, 'ANOTHER_MORE_COMPLEX_ACTION_NAME')
  equal(actionTypes.ANOTHER_MORE_COMPLEX_ACTION_NAME, 'ANOTHER_MORE_COMPLEX_ACTION_NAME')
})
