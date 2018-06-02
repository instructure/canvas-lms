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
import ReactDOM from "react-dom";
import LoadMore, { styles } from "../../../src/common/components/LoadMore";
import sd from "skin-deep";
import sinon from "sinon";
import jsdom from "mocha-jsdom";
import { css } from "aphrodite";

describe("LoadMore", () => {
  const noop = () => {};

  describe("focus handling", () => {
    let elem, props;
    jsdom();

    function renderChildren(items) {
      return (
        <ul>
          {items.map(item => (
            <li key={item}>
              <a href="#">{item}</a>
            </li>
          ))}
        </ul>
      );
    }

    beforeEach(() => {
      elem = document.createElement("div");
      elem.tabIndex = -1;
      document.body.appendChild(elem);
      elem.focus();
      props = {
        hasMore: false,
        loadMore: sinon.stub(),
        focusSelector: "li>a"
      };
    });

    afterEach(() => {
      document.body.removeChild(elem);
    });

    it("focuses first additional element that matches focusSelector", () => {
      const items = ["one"];
      const c = ReactDOM.render(
        <LoadMore {...props}>{renderChildren(items)}</LoadMore>,
        elem
      );
      items.push("two", "three");
      c.loadMore();
      ReactDOM.render(
        <LoadMore {...props}>{renderChildren(items)}</LoadMore>,
        elem
      );
      assert.equal(document.activeElement.textContent, "two");
    });

    it("does not change focus unless the number of focusable children changed", () => {
      delete props.focusSelector;
      const items = ["one"];
      const c = ReactDOM.render(
        <LoadMore {...props}>{renderChildren(items)}</LoadMore>,
        elem
      );
      c.loadMore();
      props.hasMore = true;
      ReactDOM.render(
        <LoadMore {...props}>{renderChildren(items)}</LoadMore>,
        elem
      );
      assert.equal(document.activeElement, elem);
    });

    it("does not change focus if unless focusSelect prop is passed", () => {
      delete props.focusSelector;
      const items = ["one"];
      const c = ReactDOM.render(
        <LoadMore {...props}>{renderChildren(items)}</LoadMore>,
        elem
      );
      items.push("two");
      c.loadMore();
      ReactDOM.render(
        <LoadMore {...props}>{renderChildren(items)}</LoadMore>,
        elem
      );
      assert.equal(document.activeElement, elem);
    });

    it("does not change focus unless load more is clicked", () => {
      const items = ["one"];
      ReactDOM.render(
        <LoadMore {...props}>{renderChildren(items)}</LoadMore>,
        elem
      );
      items.push("two");
      ReactDOM.render(
        <LoadMore {...props}>{renderChildren(items)}</LoadMore>,
        elem
      );
      assert.equal(document.activeElement, elem);
    });
  });

  describe("Load more results button", () => {
    it("renders if hasMore", () => {
      let tree = sd.shallowRender(
        <LoadMore hasMore loadMore={noop}>
          Results
        </LoadMore>
      );
      assert.ok(tree.subTree("Button"));
    });

    it("doesn't render if not hasMore", () => {
      let tree = sd.shallowRender(
        <LoadMore hasMore={false} loadMore={noop}>
          Results
        </LoadMore>
      );
      assert.ok(!tree.subTree("Button"));
    });

    it("doesn't render if isLoading", () => {
      let tree = sd.shallowRender(
        <LoadMore hasMore isLoading loadMore={noop}>
          Results
        </LoadMore>
      );
      assert.ok(!tree.subTree("Button"));
    });

    it("calls loadMore when clicked", () => {
      let loadMore = sinon.spy();
      let tree = sd.shallowRender(
        <LoadMore hasMore loadMore={loadMore}>
          Results
        </LoadMore>
      );
      tree.subTree("Button").props.onClick();
      assert.ok(loadMore.called);
    });
  });

  describe("Loading indicator", () => {
    it("renders if non-empty and hasMore", () => {
      let tree = sd.shallowRender(
        <LoadMore hasMore loadMore={noop}>
          <span>Result 1</span>
        </LoadMore>
      );
      assert.ok(tree.subTree("." + css(styles.loader)));
    });

    it("doesn't render if not hasMore", () => {
      let tree = sd.shallowRender(
        <LoadMore hasMore={false} loadMore={noop}>
          <span>Result 1</span>
        </LoadMore>
      );
      assert.ok(!tree.subTree("." + css(styles.loader)));
    });

    it("doesn't render if empty", () => {
      let tree = sd.shallowRender(<LoadMore hasMore loadMore={noop} />);
      assert.ok(!tree.subTree("." + css(styles.loader)));
    });

    it("visible if isLoading", () => {
      let tree = sd.shallowRender(
        <LoadMore hasMore isLoading loadMore={noop}>
          <span>Result 1</span>
        </LoadMore>
      );
      let loader = tree.subTree("." + css(styles.loader));
      assert.ok(!loader.props["aria-hidden"]);
      assert.equal(loader.props.style.opacity, 1);
    });

    it("hidden if not isLoading", () => {
      let tree = sd.shallowRender(
        <LoadMore hasMore loadMore={noop}>
          <span>Result 1</span>
        </LoadMore>
      );
      let loader = tree.subTree("." + css(styles.loader));
      assert.ok(loader.props["aria-hidden"]);
      assert.equal(loader.props.style.opacity, 0);
    });
  });
});
