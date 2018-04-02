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
import clickCallback from "../../src/rce/plugins/instructure_image/clickCallback";

let caughtEvent;

// ====================
//    FAKE OBJECTS
// ====================

let fakeDocument = {
  // extract event from file and attach it to an accessible variable
  dispatchEvent: event => {
    caughtEvent = event;
  },
  createEvent: () => {
    return {
      initCustomEvent: function(eventType, _1_, _2_, detail) {
        this.eventType = eventType;
        this.detail = detail;
      }
    };
  }
};

let fakeEditor = {
  selection: { getNode: () => "selectedNode" },
  dom: { getAttrib: () => "some string" }
};

describe("instructure_image plugin", () => {
  // ====================
  //        TESTS
  // ====================

  describe("button click", () => {
    it("dispatches a custom tinyRCE event", done => {
      // run the callback attached to button
      clickCallback(fakeEditor, fakeDocument);

      // ensure it properly sets event attrs
      assert.equal(caughtEvent.eventType, "tinyRCE/initImagePicker");
      assert.equal(caughtEvent.detail.ed, fakeEditor);
      assert.equal(caughtEvent.detail.selectedNode, "selectedNode");

      done();
    });
  });
});
