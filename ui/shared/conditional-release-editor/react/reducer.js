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

import {combineReducers} from 'redux-immutable'
import {handleActions} from 'redux-actions'
import reduceReducers from 'reduce-reducers'

import Immutable, {Map} from 'immutable'
import {onSuccessOnly} from './reducer-helpers'
import * as actions from './actions'
import scoringRangesReducer from './scoring-ranges-reducer'
import assignmentPickerReducer from './assignment-picker-reducer'

const mergePayload = (state, action) =>
  state.mergeWith((prev, next) => next || prev, action.payload)

const createRootReducer = () => {
  return reduceReducers(
    combineReducers({
      // handle piecewise state
      aria_alert: handleActions(
        {
          [actions.SET_ARIA_ALERT]: (state, action) => action.payload,
          [actions.CLEAR_ARIA_ALERT]: () => '',
          [actions.SET_GLOBAL_WARNING]: (state, action) => action.payload,
          [actions.CLEAR_GLOBAL_WARNING]: () => '',
        },
        ''
      ),

      global_error: handleActions(
        {
          [actions.LOAD_RULE_FOR_ASSIGNMENT]: gotHttpError,
          [actions.SAVE_RULE]: gotHttpError,
          [actions.GET_ASSIGNMENTS]: gotHttpError,
          [actions.DELETE_RULE]: gotHttpError,
        },
        ''
      ),

      global_warning: handleActions(
        {
          [actions.SET_GLOBAL_WARNING]: (state, action) => action.payload,
          [actions.CLEAR_GLOBAL_WARNING]: () => '',
        },
        ''
      ),

      course_id: handleActions(
        {
          [actions.SET_COURSE_ID]: (state, action) => action.payload,
        },
        ''
      ),

      rule: combineReducers({
        id: handleActions(
          {
            [actions.LOAD_RULE_FOR_ASSIGNMENT]: gotRuleSetRuleId,
            [actions.SAVE_RULE]: savedRuleSetRuleId,
          },
          ''
        ),

        scoring_ranges: scoringRangesReducer,
      }),

      assignments: handleActions(
        {
          [actions.GET_ASSIGNMENTS]: gotAssignments,
        },
        Map()
      ),

      assignment_picker: assignmentPickerReducer,

      trigger_assignment: handleActions(
        {
          [actions.UPDATE_ASSIGNMENT]: mergePayload,
        },
        Map()
      ),

      received: combineReducers({
        rule: handleActions(
          {
            [actions.LOAD_RULE_FOR_ASSIGNMENT]: () => true,
          },
          false
        ),
        assignments: handleActions(
          {
            [actions.GET_ASSIGNMENTS]: () => true,
          },
          false
        ),
      }),
    })
  )
}
export default createRootReducer

const gotHttpError = (state, action) => {
  if (!action.error) return ''
  return `${action.payload.config.method.toUpperCase()} ${action.payload.config.url}: ${
    action.payload.statusText
  } / ${action.payload.data && action.payload.data.error}`
}

const gotRuleSetRuleId = onSuccessOnly((state, action) => {
  if (!action.payload.data) return ''
  return action.payload.data.id
})

const savedRuleSetRuleId = onSuccessOnly((state, action) => {
  return action.payload.data.id
})

const gotAssignments = onSuccessOnly((state, action) => {
  if (!action.payload.data) return Map()

  const assgMap = {}

  action.payload.data.forEach(assg => {
    assgMap[assg.id] = assg
  })

  return Immutable.fromJS(assgMap)
})
