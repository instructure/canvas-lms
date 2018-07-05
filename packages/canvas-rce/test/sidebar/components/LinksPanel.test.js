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
import LinksPanel from "../../../src/sidebar/components/LinksPanel";
import sd from "skin-deep";
import sinon from "sinon";

describe("LinksPanel", () => {
  const collections = {
    announcements: { links: [] },
    assignments: { links: [] },
    discussions: { links: [] },
    modules: { links: [] },
    quizzes: { links: [] },
    wikiPages: { links: [] }
  };
  const noop = () => {};
  let defaultProps;

  beforeEach(() => {
    defaultProps = {
      contextType: "course",
      contextId: "1",
      collections: collections,
      toggleNewPageForm: noop
    };
  });

  it("binds collection name into child LinkSets' fetchInitialPage", () => {
    let spy = sinon.spy();
    let tree = sd.shallowRender(
      <LinksPanel {...defaultProps} fetchInitialPage={spy} />
    );
    const wikiPages = tree
      .dive(["CollectionPanel", "AccordionSection", "LinkSet"])
      .getMountedInstance();
    wikiPages.props.fetchInitialPage();
    assert.ok(spy.calledWith("wikiPages"));
  });

  it("binds collection name into child LinkSets' fetchNextPage", () => {
    let spy = sinon.spy();
    let tree = sd.shallowRender(
      <LinksPanel {...defaultProps} fetchNextPage={spy} />
    );
    const wikiPages = tree
      .dive(["CollectionPanel", "AccordionSection", "LinkSet"])
      .getMountedInstance();
    wikiPages.props.fetchNextPage();
    assert.ok(spy.calledWith("wikiPages"));
  });

  describe("course context", () => {
    let tree;
    before(() => {
      tree = sd.shallowRender(<LinksPanel {...defaultProps} />);
    });

    it("has expected tabs", () => {
      const panels = tree.everySubTree("CollectionPanel");
      assert.equal(panels.length, 6);
      assert.ok(panels[0].props.summary === "Pages");
      assert.ok(panels[1].props.summary === "Assignments");
      assert.ok(panels[2].props.summary === "Quizzes");
      assert.ok(panels[3].props.summary === "Announcements");
      assert.ok(panels[4].props.summary === "Discussions");
      assert.ok(panels[5].props.summary === "Modules");

      const otherPanels = tree.everySubTree("AccordionSection");
      assert.equal(otherPanels.length, 1);

      const navPanel = otherPanels[0];
      assert.ok(navPanel.props.summary === "Course Navigation");
    });

    it("mentions the course in linkToText", () => {
      assert.ok(tree.text().includes("Link to other content in the course."));
    });

    it("has 'link to new page' in Pages links", () => {
      let pagesTabTree = tree.subTree(
        "CollectionPanel",
        n => n.props.summary === "Pages"
      );
      let linkToNewPage = pagesTabTree.dive([
        "CollectionPanel",
        "LinkToNewPage"
      ]);
      assert.ok(linkToNewPage.subTree("#rcs-LinkToNewPage-btn-link"));
    });

    it("does not have 'link to new page' in Quizzes links", () => {
      let quizzesTabTree = tree.subTree(
        "CollectionPanel",
        n => n.props.summary === "Quizzes"
      );

      assert.throws(() => {
        pagesTabTree.dive(["CollectionPanel", "LinkToNewPage"]);
      });
    });

    it("does not have 'link to new page' if not allowed for session", () => {
      tree = sd.shallowRender(
        <LinksPanel {...defaultProps} canCreatePages={false} />
      );
      let pagesTabTree = tree.subTree(
        "CollectionPanel",
        n => n.props.summary === "Pages"
      );

      assert.throws(() => {
        pagesTabTree.dive(["CollectionPanel", "LinkToNewPage"])
      });
    });
  });

  describe("group context", () => {
    let tree;
    before(() => {
      let props = { ...defaultProps, contextType: "group" };
      tree = sd.shallowRender(<LinksPanel {...props} />);
    });

    it("skips Assigments, Quizzes, and Modules tabs", () => {
      const panels = tree.everySubTree("CollectionPanel");
      assert.ok(panels.every(tab => tab.props.summary !== "Assignments"));
      assert.ok(panels.every(tab => tab.props.summary !== "Quizzes"));
      assert.ok(panels.every(tab => tab.props.summary !== "Modules"));
    });

    it("has Group Navigation tab", () => {
      const panels = tree.everySubTree("AccordionSection");
      assert.ok(panels.some(tab => tab.props.summary === "Group Navigation"));
    });

    it("mentions the group in linkToText", () => {
      assert.ok(tree.text().includes("Link to other content in the group."));
    });

    it("has 'link to new page' in Pages links", () => {
      let pagesTabTree = tree.subTree(
        "CollectionPanel",
        n => n.props.summary === "Pages"
      );
      let linkToNewPage = pagesTabTree.dive([
        "CollectionPanel",
        "LinkToNewPage"
      ]);
      assert.ok(linkToNewPage.subTree("#rcs-LinkToNewPage-btn-link"));
    });
  });

  describe("user context", () => {
    let tree;
    before(() => {
      let props = { ...defaultProps, contextType: "user" };
      tree = sd.shallowRender(<LinksPanel {...props} />);
    });

    // TODO: came from canvas like this, may want to change
    it("only has Course Navigation tab", () => {
      const panelsOnlyShownToCoursesAndGroups = tree.everySubTree(
        "CollectionPanel"
      );
      assert.equal(panelsOnlyShownToCoursesAndGroups.length, 0);

      const otherPanels = tree.everySubTree("AccordionSection");
      assert.equal(otherPanels.length, 1);

      const navPanel = otherPanels[0];
      assert.ok(navPanel.props.summary === "");
    });

    it("it has no linkToText", () => {
      assert.ok(!tree.text().includes("Link to other content"));
    });

    it("does not have 'link to new page' in CourseNavigation links", () => {
      let pagesTabTree = tree.subTree(
        "CollectionPanel",
        n => n.props.summary === "Pages"
      );

      assert.throws(() => {
        pagesTabTree.dive(["CollectionPanel", "LinkToNewPage"]);
      });
    });
  });
});
