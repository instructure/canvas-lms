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

import folder from "./folder";
import * as actions from "../actions/files";

export default function foldersReducer(state = {}, action) {
  switch (action.type) {
    case actions.ADD_FOLDER:
    case actions.RECEIVE_FILES:
    case actions.INSERT_FILE:
    case actions.RECEIVE_SUBFOLDERS:
    case actions.REQUEST_FILES:
    case actions.REQUEST_SUBFOLDERS:
    case actions.TOGGLE:
      return {
        ...state,
        [action.id]: folder(state[action.id], action)
      };
    default:
      return state;
  }
}
