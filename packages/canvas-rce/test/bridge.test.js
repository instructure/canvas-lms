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
import Bridge from "../src/bridge";

describe("Editor/Sidebar bridge", () => {
  afterEach(() => {
    Bridge.focusEditor(null);
  });

  it("focusEditor sets the active editor", () => {
    let editor = {};
    Bridge.focusEditor(editor);
    assert.equal(Bridge.activeEditor(), editor);
  });

  describe("detachEditor", () => {
    let activeEditor = {};
    let otherEditor = {};

    beforeEach(() => {
      Bridge.focusEditor(activeEditor);
    });

    it("given active editor clears the active editor", () => {
      Bridge.detachEditor(activeEditor);
      assert.equal(Bridge.activeEditor(), undefined);
    });

    it("given some other editor leaves the active editor alone", () => {
      Bridge.detachEditor(otherEditor);
      assert.equal(Bridge.activeEditor(), activeEditor);
    });
  });

  describe("renderEditor", () => {
    it("sets the active editor", () => {
      let editor = {};
      Bridge.renderEditor(editor);
      assert.equal(Bridge.activeEditor(), editor);
    });

    it("accepts the first editor rendered when many rendered in a row", () => {
      let editor1 = { 1: 1 };
      let editor2 = { 2: 2 };
      let editor3 = { 3: 3 };
      Bridge.renderEditor(editor1);
      Bridge.renderEditor(editor2);
      Bridge.renderEditor(editor3);
      assert.equal(Bridge.activeEditor(), editor1);
    });
  });

  describe("insertLink", () => {
    let link = {};
    let editor = {};

    beforeEach(() => {
      sinon.stub(console, "warn");
      editor = {
        insertLink: sinon.spy(),
        props: {
          textareaId: "fake_editor",
          tinymce: {
            get(_id) {
              return {
                selection: {
                  getRng: sinon.stub().returns("some-range"),
                  getNode: sinon.stub().returns("some-node")
                }
              };
            }
          }
        }
      };
    });

    afterEach(() => {
      // eslint-disable-next-line no-console
      console.warn.restore();
    });

    it("insertLink with an active editor forwards the link to createLink", () => {

      Bridge.focusEditor(editor);
      Bridge.insertLink(link);
      assert.ok(editor.insertLink.calledWith(link));
    });

    it("insertLink with no active editor is a no-op, but warns", () => {
      Bridge.focusEditor(undefined);
      assert.doesNotThrow(() => Bridge.insertLink(link), TypeError);
      // eslint-disable-next-line no-console
      assert.ok(console.warn.called);
    });

    it("adds selectionDetails to links", () => {
      Bridge.focusEditor(editor);
      Bridge.insertLink({});
      sinon.assert.calledWithMatch(editor.insertLink, {
        selectionDetails: {
          node: "some-node",
          range: "some-range"
        }
      });
    });
  });
});
