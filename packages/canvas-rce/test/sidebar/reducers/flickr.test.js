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
import flickr from "../../../src/sidebar/reducers/flickr";
import * as actions from "../../../src/sidebar/actions/flickr";

describe("Flickr reducer", () => {
  let state;
  let action;

  beforeEach(() => {
    state = {};
  });

  it("does not modify the state if for unknown actions", () => {
    assert(flickr(state, { type: "unknown.action" }) === state);
  });

  describe("START_FLICKR_SEARCH", () => {
    beforeEach(() => {
      action = {
        type: actions.START_FLICKR_SEARCH,
        term: "chess"
      };
    });

    it("sets searching to true", () => {
      assert.ok(flickr(state, action).searching);
    });

    it("sets term from action", () => {
      assert(flickr(state, action).searchTerm == "chess");
    });
  });

  describe("RECEIVE_FLICKR_RESULTS", () => {
    beforeEach(() => {
      action = {
        type: actions.RECEIVE_FLICKR_RESULTS,
        results: [1, 2, 3]
      };
    });

    it("turns searching off", () => {
      assert.ok(!flickr(state, action).searching);
    });

    it("passes results through for display", () => {
      assert.equal(3, flickr(state, action).searchResults.length);
    });
  });

  describe("FAIL_FLICKR_SEARCH", () => {
    beforeEach(() => {
      action = {
        type: actions.FAIL_FLICKR_SEARCH,
        results: [1, 2, 3]
      };
      state.formExpanded = true;
      state.searchTerm = "chess";
    });

    it("disables searching flag", () => {
      assert.equal(false, flickr(state, action).searching);
    });

    it("blanks the search term", () => {
      assert.equal("", flickr(state, action).searchTerm);
    });

    it("empties the search results", () => {
      assert(flickr(state, action).searchResults.length == 0);
    });

    it("leaves the form state as it is", () => {
      assert.equal(state.formExpanded, flickr(state, action).formExpanded);
    });
  });

  describe("TOGGLE_FLICKR_FORM", () => {
    beforeEach(() => {
      action = { type: actions.TOGGLE_FLICKR_FORM };
      state.formExpanded = true;
    });

    it("reverses current state", () => {
      assert.equal(!state.formExpanded, flickr(state, action).formExpanded);
    });

    it("goes back and forth for each invocation", () => {
      state.formExpanded = false;
      assert.equal(true, flickr(state, action).formExpanded);
    });
  });
});
