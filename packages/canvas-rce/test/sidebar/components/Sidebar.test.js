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
import Sidebar from "../../../src/sidebar/components/Sidebar";
import sd from "skin-deep";

describe("Sidebar", () => {
  const collections = {
    announcements: { links: [] },
    assignments: { links: [] },
    discussions: { links: [] },
    modules: { links: [] },
    quizzes: { links: [] },
    wikiPages: { links: [] }
  };

  it("renders the panels when not hidden", () => {
    let tree = sd.shallowRender(
      <Sidebar
        hidden={false}
        theme={{ loaded: true, variables: {} }}
        contextType="course"
        collections={collections}
        session={{}}
        startUpload={() => {}}
      />
    );
    assert.ok(tree.subTree("LinksPanel"));
    assert.ok(tree.subTree("ImagesPanel"));
    assert.ok(tree.subTree("FilesPanel"));
  });

  it("renders a hidden div when hidden", () => {
    let tree = sd.shallowRender(
      <Sidebar hidden={true} contextType="course" collections={collections} />
    );
    assert.ok(!tree.subTree("LinksPanel"));
    assert.ok(!tree.subTree("ImagesPanel"));
    assert.ok(!tree.subTree("FilesPanel"));
  });

  describe("disableFilesPanel()", () => {
    let files, folders;
    beforeEach(() => {
      folders = {
        0: {
          id: 0,
          name: "course files",
          parentId: null,
          loading: false,
          fileIds: [],
          folderIds: []
        },
        1: {
          id: 1,
          name: "foo",
          parentId: null,
          loading: false,
          fileIds: [3],
          folderIds: [2]
        },
        2: {
          id: 2,
          name: "bar",
          parentId: 1,
          loading: false,
          fileIds: [],
          folderIds: []
        }
      };
      files = {
        3: {
          id: 3,
          name: "baz",
          type: "text/plain",
          url: "file3url"
        }
      };
    });

    it("returns true if canUploadFiles is false and it has no files or folders", () => {
      let tree = sd.shallowRender(
        <Sidebar
          hidden={true}
          canUploadFiles={false}
          contextType="course"
          collections={collections}
        />
      );
      assert.ok(tree.getMountedInstance().disableFilesPanel());
    });

    it("returns true if canUploadFiles is true and it has no files or folders", () => {
      let tree = sd.shallowRender(
        <Sidebar
          hidden={true}
          canUploadFiles={true}
          contextType="course"
          collections={collections}
        />
      );
      assert.ok(tree.getMountedInstance().disableFilesPanel());
    });

    it("returns false if canUploadFiles is true and it has files", () => {
      let tree = sd.shallowRender(
        <Sidebar
          hidden={true}
          canUploadFiles={true}
          contextType="course"
          collections={collections}
          files={files}
        />
      );
      assert.ok(!tree.getMountedInstance().disableFilesPanel());
    });

    it("returns false if canUploadFiles is true and it has folders", () => {
      let tree = sd.shallowRender(
        <Sidebar
          hidden={true}
          canUploadFiles={true}
          contextType="course"
          collections={collections}
          files={folders}
        />
      );
      assert.ok(!tree.getMountedInstance().disableFilesPanel());
    });
  });
});
