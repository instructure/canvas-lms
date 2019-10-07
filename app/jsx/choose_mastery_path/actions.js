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

import {createAction} from 'redux-actions'
import api from './api-client'

const actions = {}

actions.SET_ERROR = 'SET_ERROR'
actions.setError = createAction(actions.SET_ERROR)

actions.SET_OPTIONS = 'SET_OPTIONS'
actions.setOptions = createAction(actions.SET_OPTIONS)

actions.SELECT_OPTION = 'SELECT_OPTION'
actions.selectOption = option => {
  return (dispatch, getState) => {
    dispatch({type: actions.SELECT_OPTION, payload: option})

    api.selectOption(getState(), option).then(
      () => {},
      err => {
        dispatch({type: actions.SELECT_OPTION, payload: null})
        dispatch(actions.setError(err))
      }
    )
  }
}

export default actions
