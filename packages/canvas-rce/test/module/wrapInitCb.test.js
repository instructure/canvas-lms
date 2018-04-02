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
import sinon from "sinon";
import wrapInitCb from "../../src/rce/wrapInitCb";

let mirroredAttrs, edOpts, setAttrStub, fakeEditor, elStub, origInitCB;

class MockMutationObserver {
  observer() {}
}

describe("wrapInitCb", () => {
  before(() => {
    mirroredAttrs = {
      foo: "bar"
    };
    origInitCB = sinon.stub();
    edOpts = {
      init_instance_callback: origInitCB
    };
    setAttrStub = sinon.stub();
    elStub = {
      setAttribute: setAttrStub,
      dataset: { rich_text: false }
    };
    fakeEditor = {
      getElement: () => elStub,
      addVisual: () => {}
    };
  });

  it("tries to add attributes to el in cb", () => {
    let newEdOpts = wrapInitCb(mirroredAttrs, edOpts, MockMutationObserver);
    newEdOpts.init_instance_callback(fakeEditor);
    assert.ok(setAttrStub.calledWith("foo", "bar"));
  });

  it("sets rich_text on el", () => {
    elStub.dataset.rich_text = false;
    assert.ok(!elStub.dataset.rich_text);
    let newEdOpts = wrapInitCb(mirroredAttrs, edOpts, MockMutationObserver);
    newEdOpts.init_instance_callback(fakeEditor);
    assert.ok(elStub.dataset.rich_text);
  });

  it("still calls old cb", () => {
    let newEdOpts = wrapInitCb(mirroredAttrs, edOpts, MockMutationObserver);
    newEdOpts.init_instance_callback(fakeEditor);
    assert.ok(origInitCB.calledWith(fakeEditor));
  });
});
