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
import React from "react";
import SidebarContainer from "../../../src/sidebar/containers/Sidebar";
import sd from "skin-deep";
import { createStore } from "redux";

const store = createStore(
  state => {
    return state;
  },
  {
    ui: { hidden: true },
    flickr: { searchResults: [], searching: false, formExpanded: false },
    contextType: "group",
    collections: {
      announcements: {
        links: [{ href: "link1", title: "Example Announcement" }],
        bookmark: "nextAnnouncements",
        error: "SomethingBadHappened"
      },
      assignments: {
        links: [{ href: "link2", title: "Example Assignment" }],
        bookmark: "nextAssignments",
        loading: true
      },
      discussions: { links: [{ href: "link3", title: "Example Discussion" }] },
      modules: { links: [{ href: "link4", title: "Example Module" }] },
      quizzes: { links: [{ href: "link5", title: "Example Quiz" }] },
      wikiPages: { links: [{ href: "link6", title: "Example Wiki Page" }] }
    }
  }
);

describe("Sidebar container", () => {
  let tree;
  before(() => {
    tree = sd.shallowRender(<SidebarContainer store={store} />);
  });

  it("passes the ui.hidden from the store to the Sidebar", () => {
    const sidebar = tree.subTree("Sidebar");
    assert.equal(sidebar.props.hidden, store.getState().ui.hidden);
  });

  it("passes the contextType from the store to the Sidebar", () => {
    const sidebar = tree.subTree("Sidebar");
    assert.equal(sidebar.props.contextType, store.getState().contextType);
  });

  it("passes the transformed collections from the store to the Sidebar", () => {
    const sidebar = tree.subTree("Sidebar");
    assert.deepEqual(sidebar.props.collections, {
      announcements: {
        links: [{ href: "link1", title: "Example Announcement" }],
        hasMore: true,
        isLoading: false,
        lastError: "SomethingBadHappened"
      },
      assignments: {
        links: [{ href: "link2", title: "Example Assignment" }],
        hasMore: true,
        isLoading: true,
        lastError: undefined
      },
      discussions: {
        links: [{ href: "link3", title: "Example Discussion" }],
        hasMore: false,
        isLoading: false,
        lastError: undefined
      },
      modules: {
        links: [{ href: "link4", title: "Example Module" }],
        hasMore: false,
        isLoading: false,
        lastError: undefined
      },
      quizzes: {
        links: [{ href: "link5", title: "Example Quiz" }],
        hasMore: false,
        isLoading: false,
        lastError: undefined
      },
      wikiPages: {
        links: [{ href: "link6", title: "Example Wiki Page" }],
        hasMore: false,
        isLoading: false,
        lastError: undefined
      }
    });
  });

  describe("rendered container", () => {
    let sidebar;
    beforeEach(() => {
      sidebar = tree.subTree("Sidebar");
    });

    it("passes a fetchInitialPage callback to the Sidebar", () => {
      assert.equal(typeof sidebar.props.fetchInitialPage, "function");
    });

    it("passes a fetchNextPage callback to the Sidebar", () => {
      assert.equal(typeof sidebar.props.fetchNextPage, "function");
    });
  });
});
