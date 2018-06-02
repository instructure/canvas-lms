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
import FilesPanel from "../../../src/sidebar/components/FilesPanel";
import sd from "skin-deep";
import sinon from "sinon";

describe("FilesPanel", () => {
  let files, folders, rootFolderId, toggleFolder, onLinkClick, props;

  beforeEach(() => {
    let noop = () => {};
    let upload = {
      folders: {},
      uploading: false,
      formExpanded: false,
      rootFolderId: 0,
      folderTree: {}
    };
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
    rootFolderId = 0;
    toggleFolder = sinon.spy();
    onLinkClick = sinon.spy();
    props = {
      folders,
      files,
      toggleFolder,
      onLinkClick,
      rootFolderId,
      fetchFolders: noop,
      startUpload: noop,
      upload: upload,
      toggleUploadForm: noop
    };
  });

  describe("props cascade", () => {
    let tree, fileTreeProps;
    beforeEach(() => {
      tree = sd.shallowRender(<FilesPanel {...props} />);
      fileTreeProps = tree.subTree("FileTree").props;
    });

    it("passes files prop to FileTree component", () => {
      assert(fileTreeProps.files === props.files);
    });

    it("passes folders prop to FileTree component", () => {
      assert(fileTreeProps.folders[2] === props.folders[2]);
    });

    it("passes toggleFolder prop as onToggle to FileTree component", () => {
      assert(fileTreeProps.onToggle === props.toggleFolder);
    });

    it("passes handleSelect method as onSelect to FileTree component", () => {
      assert(fileTreeProps.onSelect === tree.getMountedInstance().handleSelect);
    });

    it("passes folder with rootFolderId as folder", () => {
      assert.deepEqual(fileTreeProps.folder, folders[rootFolderId]);
    });
  });

  describe("renderUploadForm()", () => {
    it("does not render UploadForm if indicated", () => {
      const tree = sd.shallowRender(<FilesPanel {...props} />);
      let uploadForm = tree.subTree("UploadForm");
      assert.ok(!uploadForm);
    });
    it("renders UploadForm if indicated", () => {
      let testProps = { ...props, withUploadForm: true };
      const tree = sd.shallowRender(<FilesPanel {...testProps} />);
      let uploadForm = tree.subTree("UploadForm");
      assert.ok(uploadForm);
    });
  });

  describe("handleSelect()", () => {
    it("calls onLinkClick w/ obj w/ name and href from props.files[id]", () => {
      const tree = sd.shallowRender(<FilesPanel {...props} />);
      tree.getMountedInstance().handleSelect(3);
      sinon.assert.calledWithMatch(onLinkClick, {
        title: files[3].name,
        href: files[3].url
      });
    });
  });
});
