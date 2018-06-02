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
import LinkSet from "../../../src/sidebar/components/LinkSet";
import sd from "skin-deep";
import sinon from "sinon";
import * as dragHtml from "../../../src/sidebar/dragHtml";
import * as contentRendering from "../../../src/rce/contentRendering";

describe("LinkSet", () => {
  const collection = {
    links: [
      { href: "link1", title: "Link 1" },
      { href: "link2", title: "Link 2" }
    ],
    isLoading: false,
    hasMore: true
  };

  const noop = () => {};

  it("prevents default event handling when clicked with handler", () => {
    let clicked = sinon.spy();
    let tree = sd.shallowRender(
      <LinkSet collection={collection} onLinkClick={clicked} />
    );
    const button = tree.everySubTree("a")[0];
    const event = { preventDefault: sinon.spy() };
    button.props.onClick(event);
    assert.ok(event.preventDefault.called);
  });

  it("passes link data to provided onLinkClick when clicked", () => {
    let clicked = sinon.spy();
    let tree = sd.shallowRender(
      <LinkSet collection={collection} onLinkClick={clicked} />
    );
    const button = tree.everySubTree("a")[0];
    const event = { preventDefault: noop };
    button.props.onClick(event);
    assert.ok(clicked.calledWith(collection.links[0]));
  });

  it("does not throw on click when onLinkClick absent", () => {
    let tree = sd.shallowRender(<LinkSet collection={collection} />);
    const button = tree.everySubTree("a")[0];
    const event = { preventDefault: noop };
    assert.doesNotThrow(() => button.props.onClick(event));
  });

  it("does not preventDefault on click when onLinkClick absent", () => {
    let tree = sd.shallowRender(<LinkSet collection={collection} />);
    const button = tree.everySubTree("a")[0];
    const event = { preventDefault: sinon.spy() };
    button.props.onClick(event);
    assert.ok(event.preventDefault.notCalled);
  });

  it("calls fetchInitialPage on mount when provided", () => {
    let fetchInitialPage = sinon.spy();
    sd.shallowRender(
      <LinkSet collection={collection} fetchInitialPage={fetchInitialPage} />
    );
    assert.ok(fetchInitialPage.called);
  });

  it("forwards fetchNextPage to LoadMore component", () => {
    let fetchNextPage = sinon.spy();
    let tree = sd.shallowRender(
      <LinkSet collection={collection} fetchNextPage={fetchNextPage} />
    );
    let loadMore = tree.subTree("LoadMore");
    loadMore.props.loadMore();
    assert.ok(fetchNextPage.called);
  });

  describe("rendering", () => {
    it("renders a button for each item", () => {
      let tree = sd.shallowRender(
        <LinkSet collection={collection} fetchNextPage={noop} />
      );
      const buttons = tree.everySubTree("a");
      assert.equal(buttons.length, 2);
    });

    let tree;
    describe("non-empty", () => {
      beforeEach(() => {
        tree = sd.shallowRender(
          <LinkSet collection={collection} fetchNextPage={noop} />
        );
      });

      it("renders the link list", () => {
        assert.ok(tree.subTree("ul"));
      });

      it("does not render empty indicator", () => {
        assert.ok(!tree.subTree(".rcs-LinkSet-Empty"));
      });
    });

    describe("empty but might load more", () => {
      beforeEach(() => {
        let initializingCollection = {
          links: [],
          hasMore: true,
          isLoading: true
        };
        tree = sd.shallowRender(
          <LinkSet collection={initializingCollection} fetchNextPage={noop} />
        );
      });

      it("does not render link list", () => {
        assert.ok(!tree.subTree("ul"));
      });

      it("does not render empty indicator", () => {
        assert.ok(!tree.subTree(".rcs-LinkSet-Empty"));
      });
    });

    describe("empty and done loading", () => {
      beforeEach(() => {
        let emptyCollection = { links: [], hasMore: false, isLoading: false };
        tree = sd.shallowRender(
          <LinkSet collection={emptyCollection} fetchNextPage={noop} />
        );
      });

      it("does not render the link list", () => {
        assert.ok(!tree.subTree("ul"));
      });

      it("renders empty indicator", () => {
        assert.ok(tree.subTree(".rcs-LinkSet-Empty"));
      });
    });

    describe("empty and failed loading", () => {
      beforeEach(() => {
        let emptyCollection = {
          links: [],
          hasMore: false,
          isLoading: false,
          lastError: "Borked"
        };
        tree = sd.shallowRender(
          <LinkSet collection={emptyCollection} fetchNextPage={noop} />
        );
      });

      it("does not render the link list", () => {
        assert.ok(!tree.subTree("ul"));
      });

      it("renders loading error", () => {
        assert.ok(tree.subTree(".rcs-LinkSet-LoadFailed"));
      });
    });

    describe("with fetchNextPage", () => {
      it("renders in LoadMore component if fetchNextPage provided", () => {
        tree = sd.shallowRender(
          <LinkSet collection={collection} fetchNextPage={noop} />
        );
        assert.ok(tree.subTree("LoadMore"));
      });
    });

    describe("without fetchNextPage", () => {
      it("renders without LoadMore component if fetchNextPage absent", () => {
        tree = sd.shallowRender(<LinkSet collection={collection} />);
        assert.ok(!tree.subTree("LoadMore"));
      });
    });
  });

  describe("handleDragStart", () => {
    let set, ev, linkHtml, link;

    beforeEach(() => {
      link = collection.links[0];
      linkHtml = "<a>Link</a>";
      sinon.stub(contentRendering, "renderLink").returns(linkHtml);
      sinon.stub(dragHtml, "default");
      ev = {};
      set = new LinkSet();
      set.handleDragStart(ev, link);
    });

    afterEach(() => {
      contentRendering.renderLink.restore();
      dragHtml.default.restore();
    });

    it("calls dragHtml with event and link", () => {
      sinon.assert.calledWith(dragHtml.default, ev, linkHtml);
    });

    it("renders link", () => {
      sinon.assert.calledWith(contentRendering.renderLink, link);
    });

    it("is bound to onDragStart for rendered links", () => {
      const tree = sd.shallowRender(<LinkSet collection={collection} />);
      const onDragStart = tree.subTree("a").props.onDragStart;
      onDragStart(ev);
      sinon.assert.calledWith(contentRendering.renderLink, collection.links[0]);
      sinon.assert.calledWith(dragHtml.default, ev, linkHtml);
    });
  });

  describe("handleLoadMoreClick", () => {
    let ev;

    beforeEach(() => {
      ev = { preventDefault: sinon.spy() };
    });

    it("prevents default on event", () => {
      const set = new LinkSet({});
      set.handleLoadMoreClick(ev);
      sinon.assert.called(ev.preventDefault);
    });

    it("calls fetch next page fn from props if set", () => {
      const fetchNextPage = sinon.spy();
      const set = new LinkSet({ fetchNextPage });
      set.handleLoadMoreClick(ev);
      sinon.assert.called(fetchNextPage);
    });
  });
});
