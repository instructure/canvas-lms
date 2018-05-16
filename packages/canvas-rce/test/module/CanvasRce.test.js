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

import jsdom from "mocha-jsdom";
import React from "react";
import assert from "assert";
import proxyquire from "proxyquire";
import Bridge from "../../src/bridge";
import sinon from "sinon";
import skin from "tinymce-light-skin";
import ReactDOM from "react-dom";

const fakeRCEWrapper = React.createClass({
  render: () => {
    return null;
  },
  displayName: () => {
    return "FakeRCEWrapper";
  }
});
fakeRCEWrapper["@noCallThru"] = true;

const CanvasRce = proxyquire("../../src/rce/CanvasRce", {
  "./RCEWrapper": fakeRCEWrapper,
  "./tinyRCE": {
    "@noCallThru": true,
    DOM: { loadCSS: () => {} }
  },
  "../../locales/index": { "@noCallThru": true }
}).default;

describe("CanvasRce", () => {
  jsdom();

  let target;

  beforeEach(() => {
    sinon.stub(skin, "useCanvas");
    target = document.createElement("div");
    document.body.appendChild(target);
  });

  const renderCanvasRce = props => {
    const mergedProps = Object.assign(
      {
        rceProps: {
          editorOptions: () => {
            return {};
          },
          textareaId: "someUniqueId",
          language: "en"
        }
      },
      props
    );
    ReactDOM.render(<CanvasRce {...mergedProps} />, target);
  };

  afterEach(() => {
    skin.useCanvas.restore();
    Bridge.focusEditor(null);
  });

  it("bridges newly rendered editors", done => {
    let renderCallback = rendered => {
      assert.equal(Bridge.activeEditor(), rendered);
      done();
    };
    renderCanvasRce({ renderCallback });
  });

  it("uses the canvas variant of the tinymce light skin by default", () => {
    renderCanvasRce();
    sinon.assert.called(skin.useCanvas);
  });

  it("does not use the bundled skin if skin is passed in props", () => {
    renderCanvasRce({ skin: "customSkin" });
    sinon.assert.notCalled(skin.useCanvas);
  });
});
