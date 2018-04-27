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
import NavigationPanel from "../../../src/sidebar/components/NavigationPanel";
import sd from "skin-deep";

describe("NavigationPanel", () => {
  const contextId = 47;
  describe("course context", () => {
    let tree;
    before(() => {
      tree = sd.shallowRender(
        <NavigationPanel contextType="course" contextId={contextId} />
      );
    });

    it("has expected links", () => {
      const links = tree.subTree("LinkSet").props.collection.links;
      assert.equal(links.length, 11);
      assert.ok(
        links.some(link => {
          return link.title === "Assignments";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "Pages";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "Discussions";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "Syllabus";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "Announcements";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "Quizzes";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "Files";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "Collaborations";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "Grades";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "People";
        })
      );
      assert.ok(
        links.some(link => {
          return link.title === "Modules";
        })
      );
    });

    it("is not loading more links", () => {
      const collection = tree.subTree("LinkSet").props.collection;
      assert.ok(!collection.isLoading);
    });

    it("does not have more links", () => {
      const collection = tree.subTree("LinkSet").props.collection;
      assert.ok(!collection.hasMore);
    });

    it("uses the correct context id", () => {
      const links = tree.subTree("LinkSet").props.collection.links;
      assert.ok(links.every(link => /\/47\//.test(link.href)));
    });
  });

  describe("group context", () => {
    let tree;
    before(() => {
      tree = sd.shallowRender(
        <NavigationPanel contextType="group" contextId={contextId} />
      );
    });

    it("skips Assigment List, Course Syllabus, Grades, and Modules links", () => {
      const links = tree.subTree("LinkSet").props.collection.links;
      assert.ok(
        links.every(link => {
          return link.title !== "Assignment List";
        })
      );
      assert.ok(
        links.every(link => {
          return link.title !== "Course Syllabus";
        })
      );
      assert.ok(
        links.every(link => {
          return link.title !== "Grades";
        })
      );
      assert.ok(
        links.every(link => {
          return link.title !== "Modules";
        })
      );
    });

    it("uses the correct context id", () => {
      const links = tree.subTree("LinkSet").props.collection.links;
      assert.ok(links.every(link => /\/47\//.test(link.href)));
    });
  });

  describe("user context", () => {
    let tree;
    before(() => {
      tree = sd.shallowRender(
        <NavigationPanel contextType="user" contextId={contextId} />
      );
    });

    // TODO: came from canvas like this, may want to change
    it("only has Files Index link", () => {
      const links = tree.subTree("LinkSet").props.collection.links;
      assert.equal(links.length, 1);
      assert.equal(links[0].title, "Files Index");
    });

    it("uses the correct context id", () => {
      const links = tree.subTree("LinkSet").props.collection.links;
      assert.ok(links.every(link => /\/47\//.test(link.href)));
    });
  });
});
