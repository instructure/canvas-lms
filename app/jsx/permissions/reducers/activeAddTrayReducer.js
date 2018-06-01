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
import {handleActions} from 'redux-actions'
import {actionTypes} from '../actions'

const activeAddTrayReducer = handleActions(
  {
    [actionTypes.DISPLAY_ADD_TRAY]: state => ({...state, show: true}),
    [actionTypes.HIDE_ALL_TRAYS]: state => ({...state, show: false}),
    [actionTypes.ADD_TRAY_SAVING_START]: state => ({...state, loading: true}),
    [actionTypes.ADD_TRAY_SAVING_SUCCESS]: state => ({...state, loading: false}),
    [actionTypes.ADD_TRAY_SAVING_FAIL]: state => ({...state, loading: false})
  },
  {
    show: false,
    loading: false
  }
)

export default activeAddTrayReducer
