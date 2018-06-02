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
import initialState from "../../../src/sidebar/store/initialState";
import RceApiSource from "../../../src/sidebar/sources/api";

describe("Sidebar initialState", () => {
  let source, apiSource;

  beforeEach(() => {
    source = {
      initializeCollection() {
        return {};
      },
      initializeUpload() {
        return {};
      },
      initializeImages() {
        return {};
      },
      initializeFlickr() {
        return {};
      }
    };
    apiSource = new RceApiSource();
  });

  it("accepts provided contextType", () => {
    const state = initialState({ contextType: "group" });
    assert.equal(state.contextType, "group");
  });

  it("normalizes provided contextType", () => {
    const state = initialState({ contextType: "groups" });
    assert.equal(state.contextType, "group");
  });

  it("accepts provided jwt", () => {
    const state = initialState({ jwt: "theJWT" });
    assert.equal(state.jwt, "theJWT");
  });

  it("accepts provided source", () => {
    const state = initialState({ source });
    assert.deepEqual(state.source, source);
  });

  it("accepts provided collections", () => {
    const collections = { iKnowBetterThan: "theStore" };
    const state = initialState({ collections });
    assert.deepEqual(state.collections, collections);
  });

  describe("defaults", () => {
    it("contextType to undefined", () => {
      assert.equal(initialState().contextType, undefined);
    });

    it("jwt to undefined", () => {
      assert.equal(initialState().jwt, undefined);
    });

    it("source to the api source", () => {
      assert.deepEqual(initialState().source, apiSource);
    });

    it("initial collections using source", () => {
      let state = initialState({
        source: Object.assign(source, {
          initializeCollection(endpoint) {
            return { links: [], bookmark: endpoint, loading: false };
          }
        })
      });
      assert.equal(state.collections.announcements.bookmark, "announcements");
    });
  });
});
