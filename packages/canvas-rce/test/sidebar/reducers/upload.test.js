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

import assert from "assert";
import upload from "../../../src/sidebar/reducers/upload";
import * as actions from "../../../src/sidebar/actions/upload";

describe("Upload reducer", () => {
  let state;
  let action;

  beforeEach(() => {
    state = {
      uploading: false,
      formExpanded: false,
      folders: {},
      rootFolderId: null,
      folderTree: {}
    };
  });

  it("does not modify the state if for unknown actions", () => {
    assert(upload(state, { type: "unknown.action" }) === state);
  });

  describe("START_FILE_UPLOAD", () => {
    beforeEach(() => {
      action = { type: actions.START_FILE_UPLOAD };
    });

    it("sets uploading to true", () => {
      assert.ok(upload(state, action).uploading);
    });
  });

  describe("COMPLETE_FILE_UPLOAD", () => {
    beforeEach(() => {
      action = {
        type: actions.COMPLETE_FILE_UPLOAD,
        results: {
          thumbnail_url: "http://some.url.example.com"
        }
      };
      state.uploads = [];
    });

    it("turns uploading off", () => {
      assert.ok(!upload(state, action).uploading);
    });

    it("collapses the form", () => {
      state.formExpanded = true;
      assert.equal(false, upload(state, action).formExpanded);
    });
  });

  describe("FAIL_FILE_UPLOAD", () => {
    beforeEach(() => {
      action = { type: actions.FAIL_FILE_UPLOAD };
    });

    it("disables uploading flag", () => {
      assert.equal(false, upload(state, action).uploading);
    });

    it("leaves the form state as it is", () => {
      assert.equal(state.formExpanded, upload(state, action).formExpanded);
    });
  });

  describe("RECEIVE_FOLDER", () => {
    beforeEach(() => {
      action = {
        type: actions.RECEIVE_FOLDER,
        id: 1,
        name: "course files",
        parentId: null
      };
    });

    it("adds a new property to folders keyed by id from action", () => {
      assert(upload(state, action).folders[action.id]);
    });

    it("sets id from action", () => {
      assert(upload(state, action).folders[action.id].id === action.id);
    });

    it("sets name from action", () => {
      assert(upload(state, action).folders[action.id].name === action.name);
    });

    it("keeps existing properties", () => {
      state.folders = { foo: "bar" };
      assert(upload(state, action).folders.foo === state.folders.foo);
    });

    it("sets the root folder id", () => {
      assert(upload(state, action).rootFolderId === 1);
    });
  });

  describe("FAIL_FOLDERS_LOAD", () => {
    beforeEach(() => {
      action = { type: actions.FAIL_FOLDERS_LOAD };
    });

    it("empties the folders data", () => {
      assert.equal(0, Object.keys(upload(state, action).folders).length);
    });
  });

  describe("TOGGLE_UPLOAD_FORM", () => {
    beforeEach(() => {
      action = { type: actions.TOGGLE_UPLOAD_FORM };
      state.formExpanded = true;
    });

    it("reverses current state", () => {
      assert.equal(!state.formExpanded, upload(state, action).formExpanded);
    });

    it("goes back and forth for each invocation", () => {
      state.formExpanded = false;
      assert.equal(true, upload(state, action).formExpanded);
    });
  });

  describe("PROCESSED_FOLDER_BATCH", () => {
    it("builds a folder tree with sorting", () => {
      action = {
        type: actions.PROCESSED_FOLDER_BATCH,
        folders: {
          [1]: { id: 1, name: "course files", parentId: null },
          [2]: { id: 2, name: "b", parentId: 1 },
          [3]: { id: 3, name: "a", parentId: 1 },
          [4]: { id: 4, name: "c", parentId: 1 },
          [5]: { id: 5, name: "ac", parentId: 3 },
          [6]: { id: 6, name: "ab", parentId: 3 },
          [7]: { id: 7, name: "ba", parentId: 2 },
          [8]: { id: 8, name: "aa", parentId: 3 },
          [9]: { id: 9, name: "bc", parentId: 2 }
        }
      };
      let desiredTree = {
        [1]: [3, 2, 4],
        [2]: [7, 9],
        [3]: [8, 6, 5],
        [4]: [],
        [5]: [],
        [6]: [],
        [7]: [],
        [8]: [],
        [9]: []
      };
      assert.deepEqual(upload(state, action).folderTree, desiredTree);
    });
  });
});
