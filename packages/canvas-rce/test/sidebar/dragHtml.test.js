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

import sinon from "sinon";
import dragHtml from "../../src/sidebar/dragHtml";
import * as browser from "../../src/common/browser";

let exampleHtml = "<span>my html</span>";

describe("Sidebar dragHtml", () => {
  let ev;
  beforeEach(() => {
    ev = { dataTransfer: { setData: sinon.spy() } };
  });

  afterEach(browser.reset);

  it("defaults to setting the text/html data on the event", () => {
    dragHtml(ev, exampleHtml);
    sinon.assert.calledWith(ev.dataTransfer.setData, "text/html", exampleHtml);
  });

  it("sets encoded Text instead for non-Edge IE", () => {
    browser.set({ ie: true, edge: false });
    dragHtml(ev, exampleHtml);
    sinon.assert.calledWith(
      ev.dataTransfer.setData,
      "Text",
      `data:text/mce-internal,rcs-sidebar,${escape(exampleHtml)}`
    );
  });

  describe("Edge", () => {
    beforeEach(() => {
      browser.set({ ie: true, edge: true });
      ev.dataTransfer.items = { clear: sinon.spy() };
    });

    it("still uses the text/html data", () => {
      dragHtml(ev, exampleHtml);
      sinon.assert.calledWith(
        ev.dataTransfer.setData,
        "text/html",
        exampleHtml
      );
    });

    it("clears the dataTransfer items", () => {
      dragHtml(ev, exampleHtml);
      sinon.assert.called(ev.dataTransfer.items.clear);
    });
  });
});
