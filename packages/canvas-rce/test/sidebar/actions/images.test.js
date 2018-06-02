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
import sinon from "sinon";
import * as actions from "../../../src/sidebar/actions/images";

describe("Image actions", () => {
  describe("createAddImage", () => {
    it("has the right action type", () => {
      const action = actions.createAddImage({});
      assert(action.type === actions.ADD_IMAGE);
    });

    it("includes id from first param", () => {
      const id = 47;
      const action = actions.createAddImage({ id });
      assert(action.id === id);
    });

    it("includes filename from first param", () => {
      const filename = "foo";
      const action = actions.createAddImage({ filename });
      assert(action.filename === filename);
    });

    it("includes display_name from first param", () => {
      const display_name = "bar";
      const action = actions.createAddImage({ display_name });
      assert(action.display_name === display_name);
    });

    it("includes preview_url from first param", () => {
      const url = "some_url";
      const action = actions.createAddImage({ url });
      assert(action.preview_url === url);
    });

    it("includes thumbnail_url from first param", () => {
      const thumbnail_url = "other_url";
      const action = actions.createAddImage({ thumbnail_url });
      assert(action.thumbnail_url === thumbnail_url);
    });
  });

  describe("fetchImages", () => {
    let fakeStore;

    beforeEach(() => {
      fakeStore = {
        fetchImages: () => {
          return new Promise(resolve => {
            resolve({ images: [{ one: "1" }, { two: "2" }, { three: "3" }] });
          });
        }
      };
    });

    it("fetches if first render", () => {
      let dispatchSpy = sinon.spy();
      let getState = () => {
        return {
          images: {
            records: [],
            hasMore: false,
            isLoading: false,
            requested: false
          },
          source: fakeStore
        };
      };
      return actions
        .fetchImages({ calledFromRender: true })(dispatchSpy, getState)
        .then(() => {
          assert(dispatchSpy.called);
        });
    });

    it("skips the fetch if subsequent renders", () => {
      let dispatchSpy = sinon.spy();
      let getState = () => {
        return {
          images: {
            records: [{ one: "1" }, { two: "2" }, { three: "3" }],
            hasMore: false,
            isLoading: false,
            requested: true
          },
          source: fakeStore
        };
      };
      return actions
        .fetchImages({ calledFromRender: true })(dispatchSpy, getState)
        .then(() => {
          assert(!dispatchSpy.called);
        });
    });

    it("fetches if requested and there are more to load", () => {
      let dispatchSpy = sinon.spy();
      let getState = () => {
        return {
          images: {
            records: [{ one: "1" }, { two: "2" }, { three: "3" }],
            hasMore: true,
            bookmark: "someurl",
            isLoading: false
          },
          source: fakeStore
        };
      };
      return actions
        .fetchImages({})(dispatchSpy, getState)
        .then(() => {
          assert(dispatchSpy.called);
        });
    });

    it("does not fetch if requested but no more to load", () => {
      let dispatchSpy = sinon.spy();
      let getState = () => {
        return {
          images: {
            records: [{ one: "1" }, { two: "2" }, { three: "3" }],
            hasMore: false,
            bookmark: "someurl",
            isLoading: false,
            requested: true
          },
          source: fakeStore
        };
      };
      return actions
        .fetchImages({})(dispatchSpy, getState)
        .then(() => {
          assert(!dispatchSpy.called);
        });
    });
  });
});
