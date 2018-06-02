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
import Bridge from "../../src/bridge";

describe("Bridge actions, embed image", () => {
  let mockEditor, origEditor;

  beforeEach(() => {
    mockEditor = {
      existingContentToLink: sinon.stub(),
      existingContentToLinkIsImg: sinon.stub(),
      insertImage: sinon.spy(),
      insertLink: sinon.spy()
    };
    origEditor = Bridge.getEditor();
    Bridge.focusEditor(mockEditor);
  });

  afterEach(() => {
    Bridge.focusEditor(origEditor);
  });

  it("inserts an image when no selection", () => {
    mockEditor.existingContentToLink.returns(false);
    Bridge.embedImage({});
    sinon.assert.called(mockEditor.insertImage);
  });

  it("inserts an image when image is selected", () => {
    mockEditor.existingContentToLink.returns(true);
    mockEditor.existingContentToLinkIsImg.returns(true);
    Bridge.embedImage({});
    sinon.assert.called(mockEditor.insertImage);
  });

  it("inserts a link through the bridge", () => {
    mockEditor.existingContentToLink.returns(true);
    Bridge.embedImage({});
    sinon.assert.calledWithMatch(mockEditor.insertLink, {
      embed: { type: "image" }
    });
  });
});
