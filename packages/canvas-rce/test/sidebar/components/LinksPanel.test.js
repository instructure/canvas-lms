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
    let props = { ...defaultProps, fetchInitialPage: spy };
    let tree = sd.shallowRender(<LinksPanel {...props} />);
    // returns first, which will be wikiPages
    const wikiPages = tree.subTree("LinkSet");
    wikiPages.props.fetchInitialPage();
    assert.ok(spy.calledWith("wikiPages"));
  });

  it("binds collection name into child LinkSets' fetchNextPage", () => {
    let spy = sinon.spy();
    let props = { ...defaultProps, fetchNextPage: spy };
    let tree = sd.shallowRender(<LinksPanel {...props} />);
    // returns first, which will be wikiPages
    const wikiPages = tree.subTree("LinkSet");
    wikiPages.props.fetchNextPage();
    assert.ok(spy.calledWith("wikiPages"));
  });

  describe("course context", () => {
    let tree;
    before(() => {
      tree = sd.shallowRender(<LinksPanel {...defaultProps} />);
    });

    it("has expected tabs", () => {
      const panels = tree.everySubTree("TabPanel");
      assert.equal(panels.length, 7);
      assert.ok(
        panels.some(tab => {
          return tab.props.title === "Pages";
        })
      );
      assert.ok(
        panels.some(tab => {
          return tab.props.title === "Assignments";
        })
      );
      assert.ok(
        panels.some(tab => {
          return tab.props.title === "Quizzes";
        })
      );
      assert.ok(
        panels.some(tab => {
          return tab.props.title === "Announcements";
        })
      );
      assert.ok(
        panels.some(tab => {
          return tab.props.title === "Discussions";
        })
      );
      assert.ok(
        panels.some(tab => {
          return tab.props.title === "Modules";
        })
      );
      assert.ok(
        panels.some(tab => {
          return tab.props.title === "Course Navigation";
        })
      );
    });

    it("mentions the course in linkToText", () => {
      const instance = tree.getMountedInstance();
      assert.ok(instance.linkToText().match("course"));
    });

    it("has 'link to new page' in Pages links", () => {
      let pagesTabTree = tree.everySubTree("TabPanel").filter(tab => {
        return tab.props.title === "Pages";
      });
      let linkToNewPage = pagesTabTree[0].dive(["div", "LinkToNewPage"]);
      assert.ok(linkToNewPage.findNode("#rcs-LinkToNewPage-btn-link"));
    });

    it("does not have 'link to new page' in Quizzes links", () => {
      let quizzesTabTree = tree.everySubTree("TabPanel").filter(tab => {
        return tab.props.title === "Quizzes";
      });
      assert.throws(() => {
        quizzesTabTree[0].dive(["div", "LinkToNewPage"]);
      });
    });

    it("does not have 'link to new page' if not allowed for session", () => {
      tree = sd.shallowRender(
        <LinksPanel {...defaultProps} canCreatePages={false} />
      );
      let pagesTabTree = tree.everySubTree("TabPanel").filter(tab => {
        return tab.props.title === "Pages";
      });
      assert.throws(() => {
        pagesTabTree[0].dive(["div", "LinkToNewPage"]);
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
      const panels = tree.everySubTree("TabPanel");
      assert.ok(
        panels.every(tab => {
          return tab.props.title !== "Assignments";
        })
      );
      assert.ok(
        panels.every(tab => {
          return tab.props.title !== "Quizzes";
        })
      );
      assert.ok(
        panels.every(tab => {
          return tab.props.title !== "Modules";
        })
      );
    });

    it("has Group Navigation tab", () => {
      const panels = tree.everySubTree("TabPanel");
      assert.ok(
        panels.some(tab => {
          return tab.props.title === "Group Navigation";
        })
      );
    });

    it("mentions the group in linkToText", () => {
      const instance = tree.getMountedInstance();
      assert.ok(instance.linkToText().match("group"));
    });

    it("has 'link to new page' in Pages links", () => {
      let pagesTabTree = tree.everySubTree("TabPanel").filter(tab => {
        return tab.props.title === "Pages";
      });
      let linkToNewPage = pagesTabTree[0].dive(["div", "LinkToNewPage"]);
      assert.ok(linkToNewPage.findNode("#rcs-LinkToNewPage-btn-link"));
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
      const panels = tree.everySubTree("TabPanel");
      assert.equal(panels.length, 1);
      assert.equal(panels[0].props.title, "Course Navigation");
    });

    it("it has no linkToText", () => {
      const instance = tree.getMountedInstance();
      assert.equal(instance.linkToText(), "");
    });

    it("does not have 'link to new page' in CourseNavigation links", () => {
      let pagesTabTree = tree.everySubTree("TabPanel").filter(tab => {
        return tab.props.title === "Course Navigation";
      });
      assert.throws(() => {
        pagesTabTree[0].dive(["div", "LinkToNewPage"]);
      });
    });
  });
});
