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
import IframesTableFix from "../../src/rce/IframesTableFix";

let table,
  editor,
  ifr,
  sandbox = sinon.sandbox.create();

class MockMutationObserver {
  observe() {}
}

describe("IframesTableFix - for CNVS-37129", () => {
  beforeEach(() => {
    table = { name: "table" };
    editor = {
      addVisual: () => {},
      dom: { select: () => {} }
    };
    ifr = new IframesTableFix();
  });

  afterEach(() => {
    sandbox.restore();
  });

  it("ensures hackTableInsertion hooks editor.addVisual", () => {
    const mock = sandbox
      .mock(ifr)
      .expects("addMutationObserverToTables")
      .twice()
      .withArgs(editor);
    ifr.hookAddVisual(editor, MockMutationObserver);
    editor.addVisual();
    mock.verify();
  });

  it("ensures addMutationObserverToTables adds MutationObserver to table", () => {
    sandbox
      .stub(editor.dom, "select")
      .withArgs("table")
      .returns([table]);
    const mock = sandbox
      .mock(MockMutationObserver.prototype)
      .expects("observe")
      .once()
      .withArgs(table);
    sandbox.stub(ifr, "fixIframes");
    ifr.addMutationObserverToTables(editor, MockMutationObserver);
    mock.verify();
  });

  it("ensures addMutationObserverToTables adds MutationObserver to table only once", () => {
    sandbox
      .stub(editor.dom, "select")
      .withArgs("table")
      .returns([table]);
    const mock = sandbox
      .mock(MockMutationObserver.prototype)
      .expects("observe")
      .once()
      .withArgs(table);
    sandbox.stub(ifr, "fixIframes");
    ifr.addMutationObserverToTables(editor, MockMutationObserver);
    ifr.addMutationObserverToTables(editor, MockMutationObserver);
    mock.verify();
  });

  it("ensures fixIframes is called from mutationobserver", () => {
    sandbox
      .stub(editor.dom, "select")
      .withArgs("table")
      .returns([table]);
    sandbox.stub(MockMutationObserver.prototype, "observe");
    const mock = sandbox
      .mock(ifr)
      .expects("fixIframes")
      .once();
    ifr.addMutationObserverToTables(editor, MockMutationObserver);
    mock.verify();
  });

  it("ensures fixIframes fixes iframes", () => {
    const innerHTML = "<span>gomer</span>";
    const elem = {
      tagName: "SPAN",
      getAttribute: () => {
        return "iframe";
      }
    };
    const td = { children: [elem], innerHTML: innerHTML };
    sandbox
      .stub(editor.dom, "select")
      .withArgs("td")
      .returns([td]);
    ifr.fixIframes(editor);
    assert(td.innerHTML == "<div>" + innerHTML + "</div>");
  });

  it("ensure fixIframes does not fix non-iframes", () => {
    const innerHTML = "<p><span>gomer</span></p>";
    const elem = {
      tagName: "P",
      getAttribute: () => {
        return "iframe";
      }
    };
    const td = { children: [elem], innerHTML: innerHTML };
    sandbox
      .stub(editor.dom, "select")
      .withArgs("td")
      .returns([td]);
    ifr.fixIframes(editor);
    assert(td.innerHTML == innerHTML);
  });
});
