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
import * as actions from "../../src/sidebar/actions/data";
import reducer from "../../src/sidebar/reducers";

describe("Sidebar reducer", () => {
  // collection key to use in testing
  const state = {
    contextType: "course",
    collections: {
      announcements: {
        // has bookmark, not loading
        links: [{ href: "announcement", title: "Announcement" }],
        bookmark: "announcementsBookmark",
        loading: false
      },
      modules: {
        // has bookmark, is loading
        links: [{ href: "module", title: "Module" }],
        bookmark: "modulesBookmark",
        loading: true
      }
    }
  };

  describe("REQUEST_PAGE", () => {
    it("sets the loading flag on the appropriate collection", () => {
      let newState = reducer(state, actions.requestPage("announcements"));
      assert.equal(newState.collections.announcements.loading, true);
    });

    it("leaves the other collections alone", () => {
      let newState = reducer(state, actions.requestPage("modules"));
      assert.deepEqual(
        newState.collections.announcements,
        state.collections.announcements
      );
    });

    it("leaves non-collection keys alone", () => {
      let newState = reducer(state, actions.requestPage("announcements"));
      assert.equal(newState.contextType, state.contextType);
    });
  });

  describe("RECEIVE_PAGE", () => {
    const page = {
      links: [{ href: "newLink", title: "New Link" }],
      bookmark: "newBookmark"
    };

    it("appends results to the appropriate collection", () => {
      let newState = reducer(state, actions.receivePage("modules", page));
      assert.equal(newState.collections.modules.links.length, 2);
      assert.deepEqual(newState.collections.modules.links[1], page.links[0]);
    });

    it("updates the bookmark on the appropriate collection", () => {
      let newState = reducer(state, actions.receivePage("modules", page));
      assert.equal(newState.collections.modules.bookmark, page.bookmark);
    });

    it("clears the loading flag on the appropriate collection", () => {
      let newState = reducer(state, actions.receivePage("modules", page));
      assert.equal(newState.collections.modules.loading, false);
    });

    it("leaves the other collections alone", () => {
      let newState = reducer(state, actions.requestPage("announcements", page));
      assert.deepEqual(newState.collections.modules, state.collections.modules);
    });
  });

  describe("FAIL_PAGE", () => {
    it("clears the loading flag on the appropriate collection", () => {
      let newState = reducer(state, actions.failPage("modules"));
      assert.equal(newState.collections.modules.loading, false);
    });

    it("clears the bookmark if the links are empty", () => {
      let emptyModules = Object.assign({}, state.collections.modules, {
        links: []
      });
      let emptyModulesCollections = Object.assign({}, state.collections, {
        modules: emptyModules
      });
      let emptyModulesState = Object.assign({}, state, {
        collections: emptyModulesCollections
      });
      let newState = reducer(emptyModulesState, actions.failPage("modules"));
      assert.equal(newState.collections.modules.bookmark, null);
    });

    it("leaves the links and bookmark on that collection alone otherwise", () => {
      let newState = reducer(state, actions.failPage("modules"));
      assert.deepEqual(
        newState.collections.modules.links,
        state.collections.modules.links
      );
      assert.equal(
        newState.collections.modules.bookmark,
        state.collections.modules.bookmark
      );
    });

    it("leaves the other collections alone", () => {
      let newState = reducer(state, actions.failPage("announcements"));
      assert.deepEqual(newState.collections.modules, state.collections.modules);
    });
  });
});
