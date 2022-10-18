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

import * as actions from '../actions/files'

const defaultState = {
  id: null,
  name: null,
  loadingCount: 0,
  loading: false,
  requested: false,
  expanded: false,
  filesUrl: null,
  foldersUrl: null,
  parentId: null,
  fileIds: [],
  folderIds: [],
}

export default function folderReducer(state = defaultState, action) {
  let loadingCount
  switch (action.type) {
    case actions.ADD_FOLDER:
      return {
        ...state,
        id: action.id,
        name: action.name,
        parentId: action.parentId,
        filesUrl: action.filesUrl,
        foldersUrl: action.foldersUrl,
      }
    case actions.RECEIVE_FILES:
      loadingCount = state.loadingCount - 1
      return {
        ...state,
        loadingCount,
        loading: !!loadingCount,
        fileIds: state.fileIds.concat(action.fileIds),
      }
    case actions.INSERT_FILE:
      return {
        ...state,
        fileIds: state.fileIds.concat(action.fileId),
      }
    case actions.RECEIVE_SUBFOLDERS:
      loadingCount = state.loadingCount - 1
      return {
        ...state,
        loadingCount,
        loading: !!loadingCount,
        folderIds: state.folderIds.concat(action.folderIds),
      }
    case actions.REQUEST_FILES:
      loadingCount = state.loadingCount + 1
      return {
        ...state,
        requested: true,
        loadingCount,
        loading: !!loadingCount,
      }
    case actions.REQUEST_SUBFOLDERS:
      loadingCount = state.loadingCount + 1
      return {
        ...state,
        requested: true,
        loadingCount,
        loading: !!loadingCount,
      }
    case actions.TOGGLE:
      return {
        ...state,
        expanded: !state.expanded,
      }
    default:
      return state
  }
}
