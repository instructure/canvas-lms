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
import LinkToNewPage from "../../../src/sidebar/components/LinkToNewPage";
import sd from "skin-deep";
import jsdom from "mocha-jsdom";
import sinon from "sinon";
import scroll from "../../../src/common/scroll";

describe("LinkToNewPage", () => {
  let noop = () => {};
  let fakeEvent = {
    preventDefault() {}
  };
  let defaultProps;

  jsdom();

  beforeEach(() => {
    defaultProps = {
      newPageLinkExpanded: true,
      onLinkClick: noop,
      toggleNewPageForm: noop,
      contextId: "1",
      contextType: "course"
    };
  });

  afterEach(() => {
    // skin deep sets up a global
    // when you "fillField" for document,
    // which then breaks jsdom tests
    global.document = undefined;
  });

  describe("form rendering", () => {
    it("renders form if expanded", () => {
      let props = { ...defaultProps, newPageLinkExpanded: true };
      let flickrComp = sd.shallowRender(<LinkToNewPage {...props} />);
      let instance = flickrComp.getMountedInstance();
      let searchForm = sd.shallowRender(instance.renderForm());
      assert.ok(searchForm.subTree("#new_page_drop_down"));
    });

    it("is null if not expanded", () => {
      let props = { ...defaultProps, newPageLinkExpanded: false };
      let flickrComp = sd.shallowRender(<LinkToNewPage {...props} />);
      let instance = flickrComp.getMountedInstance();
      assert.equal(null, instance.renderForm());
    });

    it("fires the handler when you click the expand link", () => {
      let clicked = false;
      let props = {
        ...defaultProps,
        newPageLinkExpanded: false,
        toggleNewPageForm: () => {
          clicked = true;
        }
      };
      let linkToNewComp = sd.shallowRender(<LinkToNewPage {...props} />);
      let vdom = linkToNewComp.getRenderOutput();
      vdom.props.children[0].props.onClick(fakeEvent);
      assert.ok(clicked);
    });
  });

  describe("pageName form use", () => {
    beforeEach(() => {
      defaultProps.newPageLinkExpanded = true;
    });

    it("passes search page name to link embeder for courses", () => {
      let link = null;
      let linkClick = ln => {
        link = ln;
      };
      let props = {
        ...defaultProps,
        onLinkClick: linkClick
      };
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...props} />);
      let instance = newLinkComp.getMountedInstance();
      let pageNameForm = sd.shallowRender(instance.renderForm());
      pageNameForm.fillField("#new-page-name-input", "page-name");
      assert.ok(pageNameForm.subTree("#rcs-LinkToNewPage-submit"));
      instance.handleSubmit(fakeEvent);
      assert.deepEqual(link, {
        href: "/courses/1/pages/page-name?titleize=0",
        title: "page-name"
      });
    });

    it("passes search page name to link embeder for groups", () => {
      let link = null;
      let linkClick = ln => {
        link = ln;
      };
      let props = {
        ...defaultProps,
        onLinkClick: linkClick,
        contextType: "group"
      };
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...props} />);
      let instance = newLinkComp.getMountedInstance();
      let pageNameForm = sd.shallowRender(instance.renderForm());
      pageNameForm.fillField("#new-page-name-input", "page-name");
      assert.ok(pageNameForm.subTree("#rcs-LinkToNewPage-submit"));
      instance.handleSubmit(fakeEvent);
      assert.deepEqual(link, {
        href: "/groups/1/pages/page-name?titleize=0",
        title: "page-name"
      });
    });
  });

  describe("handle componentDidUpdate", () => {
    beforeEach(() => {
      sinon.stub(scroll, "scrollIntoViewWDelay");
    });

    afterEach(() => {
      scroll.scrollIntoViewWDelay.restore();
    });

    it("returns if elem is not expanded", () => {
      let focusSpy = sinon.spy();
      let props = { ...defaultProps, newPageLinkExpanded: false };
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...props} />);
      let instance = newLinkComp.getMountedInstance();
      instance.pageInput = { focus: focusSpy };
      instance.componentDidUpdate();
      assert.ok(!focusSpy.calledWith());
    });

    it("returns if pageInput not defined", () => {
      let focusSpy = sinon.spy();
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...defaultProps} />);
      let instance = newLinkComp.getMountedInstance();
      instance.componentDidUpdate();
      assert.ok(!focusSpy.calledWith());
    });

    it("focuses and scrolls on component update", () => {
      let focusSpy = sinon.spy();
      //window = {innerWidth:0,innerHeight:0}
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...defaultProps} />);
      let instance = newLinkComp.getMountedInstance();
      instance.pageInput = {
        focus: focusSpy,
        parentElement: { parentElement: {} }
      };
      instance.componentDidUpdate();
      assert.ok(focusSpy.calledWith());
      assert.ok(scroll.scrollIntoViewWDelay.calledWith());
    });

    it("does not scroll on no form", () => {
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...defaultProps} />);
      let instance = newLinkComp.getMountedInstance();
      instance.pageInput = { focus: () => {} };
      instance.componentDidUpdate();
      assert.ok(scroll.scrollIntoViewWDelay.neverCalledWith());
    });
  });

  describe("scroll target validator", () => {
    it("passes with target is scroll component", () => {
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...defaultProps} />);
      let instance = newLinkComp.getMountedInstance();
      let target = { style: { overflow: "auto" } };
      let parents = { scrolled: 0 };
      assert.ok(instance.validScrollTarget(target, parents));
    });

    it("passes with target is window", () => {
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...defaultProps} />);
      let instance = newLinkComp.getMountedInstance();
      let target = window;
      let parents = { scrolled: 0 };
      assert.ok(instance.validScrollTarget(target, parents));
    });

    it("fails with parents already scrolled", () => {
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...defaultProps} />);
      let instance = newLinkComp.getMountedInstance();
      let target = window;
      let parents = { scrolled: 1 };
      assert.ok(!instance.validScrollTarget(target, parents));
    });

    it("fails with no valid target", () => {
      let newLinkComp = sd.shallowRender(<LinkToNewPage {...defaultProps} />);
      let instance = newLinkComp.getMountedInstance();
      let target = {};
      let parents = { scrolled: 0 };
      assert.ok(!instance.validScrollTarget(target, parents));
    });
  });
});
