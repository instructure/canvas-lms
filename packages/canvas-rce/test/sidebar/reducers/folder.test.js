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
import folder from "../../../src/sidebar/reducers/folder";
import * as actions from "../../../src/sidebar/actions/files";

describe("Folder sidebar reducer", () => {
  let state;

  beforeEach(() => {
    state = {};
  });

  it("does not modify the state if for unknown actions", () => {
    assert(folder(state, { type: "unknown.action" }) === state);
  });

  describe("ADD_FOLDER", () => {
    let action;

    beforeEach(() => {
      action = {
        type: actions.ADD_FOLDER,
        id: 1,
        name: "Foo",
        filesUrl: "/files/1",
        foldersUrl: "/folders/1"
      };
    });

    it("sets id from action", () => {
      assert(folder(state, action).id, action.id);
    });

    it("sets name from action", () => {
      assert(folder(state, action).name, action.name);
    });

    it("sets filesUrl from action", () => {
      assert(folder(state, action).filesUrl, action.filesUrl);
    });

    it("sets foldersUrl from action", () => {
      assert(folder(state, action).foldersUrl, action.foldersUrl);
    });

    it("keeps existing properties", () => {
      state.foo = "bar";
      assert(folder(state, action).foo, state.foo);
    });
  });

  describe("RECEIVE_FILES", () => {
    let action;

    beforeEach(() => {
      Object.assign(state, {
        fileIds: [1],
        loadingCount: 1
      });
      action = {
        type: actions.RECEIVE_FILES,
        fileIds: [2, 3, 4]
      };
    });

    it("decrements loadingCount", () => {
      assert(folder(state, action).loadingCount === state.loadingCount - 1);
    });

    it("sets loading to true if next loadingCount is not 0", () => {
      state.loadingCount = 2;
      state.loading = false;
      assert(folder(state, action).loading === true);
    });

    it("sets loading to false if next loadingCount is 0", () => {
      state.loadingCount = 1;
      state.loading = true;
      assert(folder(state, action).loading === false);
    });

    it("adds fileIds from action to existing fileIds", () => {
      assert.deepStrictEqual(folder(state, action).fileIds, [1, 2, 3, 4]);
    });

    it("keeps existing properties", () => {
      state.foo = "bar";
      assert(folder(state, action).foo, state.foo);
    });
  });

  describe("RECEIVE_SUBFOLDERS", () => {
    let action;

    beforeEach(() => {
      Object.assign(state, {
        folderIds: [1],
        loadingCount: 1
      });
      action = {
        type: actions.RECEIVE_SUBFOLDERS,
        folderIds: [2, 3, 4]
      };
    });

    it("decrements loadingCount", () => {
      assert(folder(state, action).loadingCount === state.loadingCount - 1);
    });

    it("sets loading to true if next loadingCount is not 0", () => {
      state.loadingCount = 2;
      state.loading = false;
      assert(folder(state, action).loading === true);
    });

    it("sets loading to false if next loadingCount is 0", () => {
      state.loadingCount = 1;
      state.loading = true;
      assert(folder(state, action).loading === false);
    });

    it("adds folderIds from action to existing folderIds", () => {
      assert.deepStrictEqual(folder(state, action).folderIds, [1, 2, 3, 4]);
    });

    it("keeps existing properties", () => {
      state.foo = "bar";
      assert(folder(state, action).foo, state.foo);
    });
  });

  describe("REQUEST_FILES", () => {
    let action;

    beforeEach(() => {
      Object.assign(state, {
        loadingCount: 1
      });
      action = {
        type: actions.REQUEST_FILES
      };
    });

    it("sets requested to true", () => {
      assert(folder(state, action).requested === true);
    });

    it("increments loadingCount", () => {
      assert(folder(state, action).loadingCount === state.loadingCount + 1);
    });

    it("sets loading to true if next loadingCount is not 0", () => {
      state.loadingCount = 0;
      state.loading = false;
      assert(folder(state, action).loading === true);
    });

    it("keeps existing properties", () => {
      state.foo = "bar";
      assert(folder(state, action).foo, state.foo);
    });
  });

  describe("REQUEST_SUBFOLDERS", () => {
    let action;

    beforeEach(() => {
      Object.assign(state, {
        loadingCount: 1
      });
      action = {
        type: actions.REQUEST_SUBFOLDERS
      };
    });

    it("sets requested to true", () => {
      assert(folder(state, action).requested === true);
    });

    it("increments loadingCount", () => {
      assert(folder(state, action).loadingCount === state.loadingCount + 1);
    });

    it("sets loading to true if next loadingCount is not 0", () => {
      state.loadingCount = 0;
      state.loading = false;
      assert(folder(state, action).loading === true);
    });

    it("keeps existing properties", () => {
      state.foo = "bar";
      assert(folder(state, action).foo, state.foo);
    });
  });

  describe("TOGGLE", () => {
    let action;

    beforeEach(() => {
      action = {
        type: actions.TOGGLE
      };
    });

    it("sets expanded to true if it was false", () => {
      state.expanded = false;
      assert(folder(state, action).expanded === true);
    });

    it("sets expanded to false if it was true", () => {
      state.expanded = true;
      assert(folder(state, action).expanded === false);
    });

    it("keeps existing properties", () => {
      state.foo = "bar";
      assert(folder(state, action).foo, state.foo);
    });
  });
});
