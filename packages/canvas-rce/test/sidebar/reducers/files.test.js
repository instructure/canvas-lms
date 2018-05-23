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
import files from "../../../src/sidebar/reducers/files";
import * as actions from "../../../src/sidebar/actions/files";

describe("Files reducer", () => {
  let state;

  beforeEach(() => {
    state = {};
  });

  it("does not modify the state if for unknown actions", () => {
    assert(files(state, { type: "unknown.action" }) === state);
  });

  describe("ADD_FILE", () => {
    let action;

    beforeEach(() => {
      action = {
        type: actions.ADD_FILE,
        id: 1,
        name: "Foo",
        fileType: "text/plain",
        url: "/files/1",
        embed: { type: "scribd" }
      };
    });

    it("adds a new property to files keyed by id from action", () => {
      assert(files(state, action)[action.id]);
    });

    it("sets id from action", () => {
      assert(files(state, action)[action.id].id === action.id);
    });

    it("sets name from action", () => {
      assert(files(state, action)[action.id].name === action.name);
    });

    it("sets type from action fileType", () => {
      assert(files(state, action)[action.id].type === action.fileType);
    });

    it("sets url from action", () => {
      assert(files(state, action)[action.id].url === action.url);
    });

    it("sets embed from action", () => {
      assert(files(state, action)[action.id].embed === action.embed);
    });

    it("keeps existing properties", () => {
      state.foo = "bar";
      assert(files(state, action).foo === state.foo);
    });
  });
});
