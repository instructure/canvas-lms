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

const RceModule = proxyquire("../../src/rce/root", {
  "./RCEWrapper": fakeRCEWrapper,
  "./tinyRCE": {
    "@noCallThru": true,
    DOM: { loadCSS: () => {} }
  },
  "../../locales/index": { "@noCallThru": true }
});

describe("RceModule", () => {
  jsdom();

  let target;
  let props;

  beforeEach(() => {
    sinon.stub(skin, "useCanvas");
    target = document.createElement("div");
    props = {
      editorOptions: () => {
        return {};
      }
    };
  });

  afterEach(() => {
    skin.useCanvas.restore();
    Bridge.focusEditor(null);
  });

  it("bridges newly rendered editors", done => {
    let callback = rendered => {
      assert.equal(Bridge.activeEditor(), rendered);
      done();
    };
    RceModule.renderIntoDiv(target, props, callback);
  });

  it("uses the canvas variant of the tinymce light skin by default", () => {
    props.skin = null;
    RceModule.renderIntoDiv(target, props, () => {});
    sinon.assert.called(skin.useCanvas);
  });

  it("does not use the bundled skin if skin is passed in props", () => {
    props.skin = "custom skin";
    RceModule.renderIntoDiv(target, props, () => {});
    sinon.assert.notCalled(skin.useCanvas);
  });

  it("handleUnmount unmounts root component", () => {
    sinon.stub(ReactDOM, "unmountComponentAtNode");
    RceModule.renderIntoDiv(target, props, wrapper => {
      wrapper.props.handleUnmount();
    });
    sinon.assert.calledWithExactly(ReactDOM.unmountComponentAtNode, target);
    ReactDOM.unmountComponentAtNode.restore();
  });
});
