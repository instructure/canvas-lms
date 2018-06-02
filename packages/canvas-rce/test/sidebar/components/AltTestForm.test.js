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
import AltTextForm from "../../../src/sidebar/components/AltTextForm";
import sinon from "sinon";
import sd from "skin-deep";

describe("AltTextForm", () => {
  const noop = () => {};
  let altComp;

  beforeEach(() => {
    altComp = sd.shallowRender(<AltTextForm altResolved={noop} />);
  });

  describe("form rendering", () => {
    it("renders TextInput and Checkbox elements", () => {
      assert.ok(altComp.subTree("TextInput"));
      assert.ok(altComp.subTree("Checkbox"));
    });

    it("disables/enables TextInput when Checkbox is toggled", () => {
      const instance = altComp.getMountedInstance();
      let vdom = altComp.subTree("TextInput").getRenderOutput();
      assert.equal(vdom.props.disabled, false);
      instance.handleDecorativeCheckbox({ target: { checked: true } });
      vdom = sd
        .shallowRender(instance.render())
        .subTree("TextInput")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, true);
      instance.handleDecorativeCheckbox({ target: { checked: false } });
      vdom = sd
        .shallowRender(instance.render())
        .subTree("TextInput")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, false);
    });
  });

  describe("alt resolution", () => {
    let mockAltResolved, instance;
    beforeEach(() => {
      mockAltResolved = sinon.spy();
      instance = altComp = sd
        .shallowRender(<AltTextForm altResolved={mockAltResolved} />)
        .getMountedInstance();
    });

    it("resolves/unresolves alt when Checkbox is toggled", () => {
      instance.handleDecorativeCheckbox({ target: { checked: true } });
      instance.handleDecorativeCheckbox({ target: { checked: false } });
      assert.equal(mockAltResolved.firstCall.args[0], true);
      assert.equal(mockAltResolved.secondCall.args[0], false);
    });

    it("resolves/unresolves alt when alt-text is entered/cleared", () => {
      instance.handleAltTextChange({ target: { value: "alt text" } });
      instance.handleAltTextChange({ target: { value: "" } });
      assert.equal(mockAltResolved.firstCall.args[0], true);
      assert.equal(mockAltResolved.secondCall.args[0], false);
    });

    it("resolves alt when alt-text is entered and Checkbox is unchecked", () => {
      instance.handleAltTextChange({ target: { value: "alt text" } });
      instance.handleDecorativeCheckbox({ target: { checked: true } });
      instance.handleDecorativeCheckbox({ target: { value: false } });
      assert.equal(mockAltResolved.lastCall.args[0], true);
    });

    it("resolves alt when Checkbox is checked and alt-text is cleared", () => {
      instance.handleAltTextChange({ target: { value: "alt text" } });
      instance.handleDecorativeCheckbox({ target: { checked: true } });
      instance.handleAltTextChange({ target: { value: "" } });
      assert.equal(mockAltResolved.lastCall.args[0], true);
    });

    it("unresolves alt when Checkbox is unchecked and alt-text is cleared", () => {
      instance.handleAltTextChange({ target: { value: "alt text" } });
      instance.handleDecorativeCheckbox({ target: { checked: true } });
      instance.handleAltTextChange({ target: { value: "" } });
      instance.handleDecorativeCheckbox({ target: { checked: false } });
      assert.equal(mockAltResolved.lastCall.args[0], false);
    });
  });
});
