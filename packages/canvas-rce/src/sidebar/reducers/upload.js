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

import {
  START_FILE_UPLOAD,
  FAIL_FILE_UPLOAD,
  TOGGLE_UPLOAD_FORM,
  COMPLETE_FILE_UPLOAD,
  RECEIVE_FOLDER,
  FAIL_FOLDERS_LOAD,
  PROCESSED_FOLDER_BATCH
} from "../actions/upload";
import { combineReducers } from "redux";

function uploading(state = false, action) {
  switch (action.type) {
    case START_FILE_UPLOAD:
      return true;
    case FAIL_FILE_UPLOAD:
    case COMPLETE_FILE_UPLOAD:
      return false;
    default:
      return state;
  }
}

function formExpanded(state = false, action) {
  switch (action.type) {
    case COMPLETE_FILE_UPLOAD:
      return false;
    case TOGGLE_UPLOAD_FORM:
      return !state;
    default:
      return state;
  }
}

function folders(state = {}, action) {
  switch (action.type) {
    case RECEIVE_FOLDER:
      return {
        ...state,
        [action.id]: {
          id: action.id,
          name: action.name,
          parentId: action.parentId
        }
      };
    case FAIL_FOLDERS_LOAD:
    default:
      return state;
  }
}

function rootFolderId(state = null, action) {
  switch (action.type) {
    case RECEIVE_FOLDER:
      if (action.parentId === null) {
        return action.id;
      } else {
        return state;
      }
    default:
      return state;
  }
}

// Returns an mapping of folder id -> list of children ids,
// with the children sorted alphabetically by name.
function folderTree(state = {}, action) {
  switch (action.type) {
    case PROCESSED_FOLDER_BATCH: {
      const folders = action.folders;
      let tree = {};

      for (let folderId in folders) {
        let folder = folders[folderId];
        tree[folder.id] = tree[folder.id] || [];
        if (folder.parentId) {
          tree[folder.parentId] = tree[folder.parentId] || [];
          tree[folder.parentId].push(folder.id);
        }
      }

      for (let parentFolderId in tree) {
        let children = tree[parentFolderId];
        children.sort(function(a, b) {
          return folders[a].name.localeCompare(folders[b].name);
        });
      }

      return tree;
    }
    default:
      return state;
  }
}

export default combineReducers({
  uploading,
  formExpanded,
  folders,
  rootFolderId,
  folderTree
});
