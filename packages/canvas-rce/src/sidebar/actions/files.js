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

export const ADD_FILE = "action.files.add_file";
export const ADD_FOLDER = "action.files.add_folder";
export const RECEIVE_FILES = "action.files.receive_files";
export const INSERT_FILE = "action.files.insert_file";
export const RECEIVE_SUBFOLDERS = "action.files.receive_subfolders";
export const REQUEST_FILES = "action.files.request_files";
export const REQUEST_SUBFOLDERS = "action.files.request_subfolders";
export const TOGGLE = "action.files.toggle";
export const SET_ROOT = "action.files.set_root";

export function createToggle(id) {
  return {
    type: TOGGLE,
    id
  };
}

export function createAddFile({ id, name, url, type, embed }) {
  return {
    type: ADD_FILE,
    id,
    name,
    url,
    embed,
    fileType: type
  };
}

export function createRequestFiles(id) {
  return {
    type: REQUEST_FILES,
    id
  };
}

export function createReceiveFiles(id, files) {
  return {
    type: RECEIVE_FILES,
    id,
    fileIds: files.map(file => file.id)
  };
}

export function createInsertFile(id, fileId) {
  return {
    type: INSERT_FILE,
    id,
    fileId
  };
}

export function requestFiles(id, bookmark) {
  return (dispatch, getState) => {
    const { source, folders } = getState();
    dispatch(createRequestFiles(id));
    return source
      .fetchFiles(bookmark || folders[id].filesUrl)
      .then(({ files, bookmark }) => {
        dispatch(
          files.map(createAddFile).concat(createReceiveFiles(id, files))
        );
        if (bookmark) {
          // Page through all in folder, pagination links if a tree may be
          // weird, epecially since files and folders are independent.
          dispatch(requestFiles(id, bookmark));
        }
      });
  };
}

export function createAddFolder(folder) {
  return {
    type: ADD_FOLDER,
    id: folder.id,
    name: folder.name,
    parentId: folder.parentId,
    filesUrl: folder.filesUrl,
    foldersUrl: folder.foldersUrl
  };
}

export function createRequestSubfolders(id) {
  return {
    type: REQUEST_SUBFOLDERS,
    id
  };
}

export function createReceiveSubfolders(id, folders) {
  return {
    type: RECEIVE_SUBFOLDERS,
    id,
    folderIds: folders.map(folder => folder.id)
  };
}

export function requestSubfolders(id, bookmark) {
  return (dispatch, getState) => {
    const { source, folders } = getState();
    dispatch(createRequestSubfolders(id));
    return source
      .fetchPage(bookmark || folders[id].foldersUrl)
      .then(({ folders, bookmark }) => {
        dispatch(
          folders
            .map(createAddFolder)
            .concat(createReceiveSubfolders(id, folders, bookmark))
        );
        if (bookmark) {
          // Page through all in folder, pagination links if a tree may be
          // weird, epecially since files and folders are independent.
          dispatch(requestSubfolders(id, bookmark));
        }
      });
  };
}

export function toggle(id) {
  return (dispatch, getState) => {
    dispatch(createToggle(id));
    const folder = getState().folders[id];
    if (!folder.requested && folder.expanded) {
      dispatch(requestSubfolders(folder.id));
      dispatch(requestFiles(folder.id));
    }
  };
}

export function createSetRoot(id) {
  return {
    type: SET_ROOT,
    id
  };
}

export function init(dispatch, getState) {
  const props = getState();
  return props.source.fetchRootFolder(props).then(({ folders }) => {
    const root = folders[0];
    if (root) {
      dispatch([createAddFolder(root), createSetRoot(root.id)]);
      dispatch(toggle(root.id));
    }
  });
}
