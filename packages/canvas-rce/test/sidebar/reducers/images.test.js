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
import images from "../../../src/sidebar/reducers/images";
import * as actions from "../../../src/sidebar/actions/images";

describe("Images reducer", () => {
  let state;

  beforeEach(() => {
    state = {
      records: [],
      hasMore: false,
      isLoading: false
    };
  });

  it("does not modify the state if for unknown actions", () => {
    assert(images(state, { type: "unknown.action" }) === state);
  });

  describe("ADD_IMAGE", () => {
    let action;

    beforeEach(() => {
      action = {
        type: actions.ADD_IMAGE,
        id: 1,
        filename: "Foo",
        display_name: "Bar",
        preview_url: "some_url",
        thumbnail_url: "other_url"
      };
    });

    it("adds a new object to images array", () => {
      assert(images(state, action).records[0]);
    });

    it("sets id from action", () => {
      assert(images(state, action).records[0].id === action.id);
    });

    it("sets filename from action", () => {
      assert(images(state, action).records[0].filename === action.filename);
    });

    it("sets display_name from action display_name", () => {
      assert(images(state, action).records[0].type === action.fileType);
    });

    it("sets preview_url from action preview_url", () => {
      assert(
        images(state, action).records[0].preview_url === action.preview_url
      );
    });

    it("sets thumbnail_url from action thumbnail_url", () => {
      assert(
        images(state, action).records[0].thumbnail_url === action.thumbnail_url
      );
    });

    it("sets href from action preview_url", () => {
      assert(images(state, action).records[0].href === action.preview_url);
    });
  });

  describe("RECEIVE_IMAGES", () => {
    it("appends new records to the existing array", () => {
      let action = {
        type: actions.RECEIVE_IMAGES,
        imageRecords: [{ id: 1 }, { id: 2 }]
      };
      assert.equal(images(state, action).records.length, 2);
    });

    it("hasMore if there's a bookmark", () => {
      let action = {
        type: actions.RECEIVE_IMAGES,
        imageRecords: [{ id: 1 }, { id: 2 }],
        bookmark: "some bookmark"
      };
      assert(images(state, action).hasMore);
    });

    it("clears isLoading state", () => {
      state.isLoading = true;
      let action = {
        type: actions.RECEIVE_IMAGES,
        imageRecords: [{ id: 1 }, { id: 2 }]
      };
      assert.equal(images(state, action).isLoading, false);
    });
  });

  describe("REQUEST_IMAGES", () => {
    it("marks images as loading", () => {
      let action = { type: actions.REQUEST_IMAGES };
      assert(images(state, action).isLoading);
    });

    it("sets requested to true", () => {
      let action = { type: actions.REQUEST_IMAGES };
      assert(images(state, action).requested);
    });
  });
});
