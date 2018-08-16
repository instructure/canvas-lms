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

// Pending is called if a delete action has just happened, and we may need to
// handle some focus management stuff in a special way because of it. Cleanup
// will be called when everything has been properly handled.
const deleteFocusReducer = handleActions(
  {
    [actionTypes.DELETE_FOCUS_PENDING]: () => true,
    [actionTypes.DELETE_FOCUS_CLEANUP]: () => false
  },
  false
)

export default deleteFocusReducer
