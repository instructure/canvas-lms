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
import * as actions from "../../../src/sidebar/actions/data";
import sinon from "sinon";
import { spiedStore } from "./utils";

describe("Sidebar data actions", () => {
  // collection key to use in testing
  const collectionKey = "theCollection";

  // trivial "always succeeds" source
  const successPage = { links: "successLinks", bookmark: "successBookmark" };
  const successSource = {
    fetchPage() {
      return new Promise(resolve => {
        resolve(successPage);
      });
    }
  };

  // trivial "always fails" source
  const brokenError = new Error("broken");
  const brokenSource = {
    fetchPage() {
      return new Promise(() => {
        throw brokenError;
      });
    }
  };

  // returns a "black hole" source that spies fetchPage
  function stubbedSource() {
    return {
      fetchPage: sinon.stub().returns(new Promise(() => {}))
    };
  }

  // constants for testing that can be overridden in props to storeState (see
  // below)
  const defaults = {
    jwt: "theJWT",
    source: successSource,
    links: [],
    bookmark: "bookmark",
    loading: false
  };

  // defaults and reshapes the given props into the shape needed by the store
  function setupState(props) {
    let { jwt, source, links, bookmark, loading } = Object.assign(
      {},
      defaults,
      props
    );
    let collection = { links, bookmark, loading };
    let collections = { [collectionKey]: collection };
    return { jwt, source, collections };
  }

  describe("fetchPage", () => {
    it("dispatches requestPage first", () => {
      let store = spiedStore(setupState());
      store.dispatch(actions.fetchPage(collectionKey));
      let callArgs = store.spy.getCall(1).args[0];
      assert.equal(callArgs.type, actions.REQUEST_PAGE);
      assert.equal(callArgs.key, collectionKey);
    });

    it("uses bookmark from store to call source.fetchPage", () => {
      let source = stubbedSource();
      let state = setupState({ source });
      let store = spiedStore(state);
      store.dispatch(actions.fetchPage(collectionKey));
      assert.ok(source.fetchPage.calledWith(defaults.bookmark));
    });

    it("dispatches receivePage with page retrieved from source", done => {
      let store = spiedStore(setupState());
      store
        .dispatch(actions.fetchPage(collectionKey))
        .then(() => {
          let callArgs = store.spy.lastCall.args[0];
          assert.equal(callArgs.type, actions.RECEIVE_PAGE);
          assert.equal(callArgs.key, collectionKey);
          assert.equal(callArgs.links, successPage.links);
          assert.equal(callArgs.bookmark, successPage.bookmark);
          done();
        })
        .catch(done);
    });

    it("dispatches failPage on error retrieving page from source", done => {
      let store = spiedStore(setupState({ source: brokenSource }));
      store
        .dispatch(actions.fetchPage(collectionKey))
        .then(() => {
          let callArgs = store.spy.lastCall.args[0];
          assert.equal(callArgs.type, actions.FAIL_PAGE);
          assert.equal(callArgs.key, collectionKey);
          assert.equal(callArgs.error, brokenError);
          done();
        })
        .catch(done);
    });
  });

  describe("fetchNextPage", () => {
    it("fetches next page if collection has bookmark and is not loading", () => {
      let store = spiedStore(setupState());
      store.dispatch(actions.fetchNextPage(collectionKey));
      assert.ok(
        store.spy.calledWith({ type: actions.REQUEST_PAGE, key: collectionKey })
      );
    });

    it("skips fetching next page if collection has no bookmark", () => {
      let store = spiedStore(setupState({ bookmark: null }));
      store.dispatch(actions.fetchNextPage(collectionKey));
      assert.ok(
        store.spy.neverCalledWith({
          type: actions.REQUEST_PAGE,
          key: collectionKey
        })
      );
    });

    it("skips fetching next page if collection is already loading", () => {
      let store = spiedStore(setupState({ loading: true }));
      store.dispatch(actions.fetchNextPage(collectionKey));
      assert.ok(
        store.spy.neverCalledWith({
          type: actions.REQUEST_PAGE,
          key: collectionKey
        })
      );
    });
  });

  describe("fetchInitialPage", () => {
    it("fetches initial page if collection is empty, has bookmark, and is not loading", () => {
      let store = spiedStore(setupState());
      store.dispatch(actions.fetchInitialPage(collectionKey));
      assert.ok(
        store.spy.calledWith({ type: actions.REQUEST_PAGE, key: collectionKey })
      );
    });

    it("skips fetching initial page if collection is not empty", () => {
      let store = spiedStore(
        setupState({ links: [{ href: "link", title: "A Link" }] })
      );
      store.dispatch(actions.fetchInitialPage(collectionKey));
      assert.ok(
        store.spy.neverCalledWith({
          type: actions.REQUEST_PAGE,
          key: collectionKey
        })
      );
    });

    it("skips fetching initial page if collection has no bookmark", () => {
      let store = spiedStore(setupState({ bookmark: null }));
      store.dispatch(actions.fetchInitialPage(collectionKey));
      assert.ok(
        store.spy.neverCalledWith({
          type: actions.REQUEST_PAGE,
          key: collectionKey
        })
      );
    });

    it("skips fetching initial page if collection is already loading", () => {
      let store = spiedStore(setupState({ loading: true }));
      store.dispatch(actions.fetchInitialPage(collectionKey));
      assert.ok(
        store.spy.neverCalledWith({
          type: actions.REQUEST_PAGE,
          key: collectionKey
        })
      );
    });
  });
});
