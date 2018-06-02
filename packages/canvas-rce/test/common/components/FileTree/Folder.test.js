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
import Folder from "../../../../src/common/components/FileTree/Folder";
import sd from "skin-deep";
import sinon from "sinon";

describe("FileTree/Folder", () => {
  let files, folders, folder, onToggle, onSelect, props;

  beforeEach(() => {
    folders = {
      1: {
        id: 1,
        name: "foo",
        loading: false,
        fileIds: [3],
        folderIds: [2]
      },
      2: {
        id: 2,
        name: "bar",
        loading: false,
        fileIds: [],
        folderIds: []
      }
    };
    folder = folders[1];
    files = {
      3: {
        id: 3,
        name: "baz",
        type: "text/plain"
      }
    };
    onToggle = sinon.spy();
    onSelect = sinon.spy();
    props = { folder, folders, files, onToggle, onSelect };
  });

  it("renders a button with the folder name", () => {
    const tree = sd.shallowRender(<Folder {...props} />);
    const text = tree.textIn("button").trim();
    assert(new RegExp(folder.name).test(text));
  });

  it("shows loading if expanded and loading prop is true", () => {
    Object.assign(folder, {
      loading: true,
      expanded: true
    });
    const tree = sd.shallowRender(<Folder {...props} />);
    assert(tree.subTree("Loading"));
  });

  it("does not show loading if loading is false", () => {
    folder.loading = false;
    const tree = sd.shallowRender(<Folder {...props} />);
    assert(tree.subTree("Loading") === false);
  });

  it("does not show loading if loading is true but not expanded", () => {
    Object.assign(folder, {
      loading: true,
      expanded: false
    });
    const tree = sd.shallowRender(<Folder {...props} />);
    assert(tree.subTree("Loading") === false);
  });

  it("renders subdirectories with correct props when expaneded", () => {
    folder.expaned = true;
    const tree = sd.shallowRender(<Folder {...props} />);
    const subs = tree.everySubTree("Folder");
    subs.forEach(sub => {
      assert(folder.folderIds.indexOf(sub.props.folderId) !== -1);
      assert(sub.props.folders === folders);
      assert(sub.props.files === files);
      assert(sub.props.onToggle === onToggle);
      assert(sub.props.onSelect === onSelect);
    });
  });

  it("does not render subdirectories when not expaneded", () => {
    folder.expaned = false;
    const tree = sd.shallowRender(<Folder {...props} />);
    const subs = tree.everySubTree("Folder");
    assert(subs.length === 0);
  });

  it("renders files with correct props when expaneded", () => {
    folder.expaned = true;
    const tree = sd.shallowRender(<Folder {...props} />);
    const subs = tree.everySubTree("File");
    subs.forEach(sub => {
      assert(sub.props.file === files[sub.props.file.id]);
      assert(sub.props.onSelect === onSelect);
    });
  });

  it("does not render files when not expaneded", () => {
    folder.expaned = false;
    const tree = sd.shallowRender(<Folder {...props} />);
    const subs = tree.everySubTree("File");
    assert(subs.length === 0);
  });

  it("calls onToggle with folder id when button is clicked", () => {
    const tree = sd.shallowRender(<Folder {...props} />);
    tree.subTree("button").props.onClick({});
    sinon.assert.calledWith(onToggle, folder.id);
  });

  it("does not throw when onToggle is not defined", () => {
    delete props.onToggle;
    const tree = sd.shallowRender(<Folder {...props} />);
    assert.doesNotThrow(() => tree.subTree("button").props.onClick({}));
  });

  it("sets aria expanded to true if expanded", () => {
    folder.expanded = true;
    const tree = sd.shallowRender(<Folder {...props} />);
    assert(tree.subTree("button").props["aria-expanded"]);
  });

  it("sets aria expanded to false if not expanded", () => {
    folder.expanded = false;
    const tree = sd.shallowRender(<Folder {...props} />);
    assert(!tree.subTree("button").props["aria-expanded"]);
  });
});
