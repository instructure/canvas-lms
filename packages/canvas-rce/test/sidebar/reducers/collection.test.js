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
import collection from "../../../src/sidebar/reducers/collection";
import * as actions from "../../../src/sidebar/actions/data";

describe("Collection reducer", () => {
  let state;

  beforeEach(() => {
    state = {};
  });

  it("does not modify the state if for unknown actions", () => {
    assert(collection(state, { type: "unknown.action" }) === state);
  });

  describe("REQUEST_PAGE", () => {
    let action = {
      type: actions.REQUEST_PAGE
    };

    it("sets the loading flag", () => {
      assert.equal(collection(state, action).loading, true);
    });

    it("preserves existing state", () => {
      state.arbitrary = "data";
      assert.equal(collection(state, action).arbitrary, "data");
    });
  });

  describe("FAIL_PAGE", () => {
    let action;

    beforeEach(() => {
      action = {
        type: actions.FAIL_PAGE,
        error: "somethingBad"
      };
      state.bookmark = "someBookmark";
      state.links = [];
    });

    it("deactivates loading", () => {
      state.loading = true;
      assert.equal(collection(state, action).loading, false);
    });

    it("includes the error in state", () => {
      assert.equal(collection(state, action).error, "somethingBad");
    });

    it("blanks the bookmark if there are no links", () => {
      assert.equal(collection(state, action).bookmark, null);
    });

    it("leaves the bookmark when links are present", () => {
      state.links = [{}, {}, {}];
      assert.equal(collection(state, action).bookmark, "someBookmark");
    });
  });
});
