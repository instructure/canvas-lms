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

import {handleActions} from 'redux-actions'
import {actionTypes} from '../actions'
import {defaultState} from '../store'

export default handleActions(
  {
    [actionTypes.SET_INPUT_PARAMS]: function setReducer(state, action) {
      // replace state with new values
      return action.payload
    },
    [actionTypes.RESET]: function resetReducer(state, action) {
      // reset to default state, except for canReadSIS, which has to persist across invocations
      const resetState = {...defaultState.inputParams, canReadSIS: state.canReadSIS}
      return !action.payload || action.payload.includes('inputParams') ? resetState : state
    },
  },
  defaultState.inputParams
)
