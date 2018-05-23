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
import File from "../../../../src/common/components/FileTree/File";
import sd from "skin-deep";
import sinon from "sinon";

describe("FileTree/File", () => {
  let file;

  beforeEach(() => {
    file = {
      id: 1,
      name: "foo",
      type: "text/plain"
    };
  });

  it("renders a button with file name", () => {
    const tree = sd.shallowRender(<File file={file} />);
    const text = tree.textIn("button").trim();
    assert(new RegExp(file.name).test(text));
  });

  it("calls onSelect with file id when button is clicked", () => {
    const spy = sinon.spy();
    const tree = sd.shallowRender(<File file={file} onSelect={spy} />);
    tree.subTree("button").props.onClick({});
    sinon.assert.calledWith(spy, file.id);
  });

  it("does not throw when onSelect is not defined", () => {
    const tree = sd.shallowRender(<File file={file} />);
    assert.doesNotThrow(() => tree.subTree("button").props.onClick({}));
  });
});
