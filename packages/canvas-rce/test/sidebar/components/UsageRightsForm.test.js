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

import { ok, equal } from "assert";
import React from "react";
import UsageRightsForm from "../../../src/sidebar/components/UsageRightsForm";
import sd from "skin-deep";

describe("UsageRightsForm", () => {
  let form, instance;

  beforeEach(() => {
    form = sd.shallowRender(<UsageRightsForm />);
    instance = form.getMountedInstance();
  });

  describe("render", () => {
    it("renders alert if no right is selected", () => {
      instance.setState({ usageRight: "" });
      ok(form.subTree("Alert"));
    });

    it("hides alert if right is selected", () => {
      instance.setState({ usageRight: "creative_commons" });
      ok(!form.subTree(".rcs-UsageRightsForm-alert"));
    });

    it("renders cc select if right is creative commons", () => {
      instance.setState({ usageRight: "creative_commons" });
      const licence = form.everySubTree("Select").find(tree => {
        return tree.props.onChange === instance.handleCCLicense;
      });
      ok(licence);
    });

    it("hides cc select if right is not creative commons", () => {
      instance.setState({ usageRight: "own_copyright" });
      const licence = form.everySubTree("Select").find(tree => {
        return tree.props.onChange === instance.handleCCLicense;
      });
      ok(!licence);
    });
  });

  describe("events handlers", () => {
    let event;

    beforeEach(() => {
      event = {
        preventDefault() {},
        target: { value: "foo" }
      };
    });

    it("handleUsageRight", () => {
      instance.handleUsageRight(event);
      equal(instance.state.usageRight, event.target.value);
    });

    it("handleCCLicense", () => {
      instance.handleCCLicense(event);
      equal(instance.state.ccLicense, event.target.value);
    });

    it("handleCopyrightHolder", () => {
      instance.handleCopyrightHolder(event);
      equal(instance.state.copyrightHolder, event.target.value);
    });
  });

  describe("value", () => {
    it("returns null of usage right is not selected", () => {
      instance.setState({ usageRight: "" });
      equal(instance.value(), null);
    });

    it("returns object with usage right and copyright holder", () => {
      const state = { usageRight: "own_copyright", copyrightHolder: "me" };
      instance.setState(state);
      const value = instance.value();
      equal(value.usageRight, state.usageRight);
      equal(value.copyrightHolder, state.copyrightHolder);
    });

    it("has ccLicese if usage right is creative commons", () => {
      const state = { usageRight: "creative_commons", ccLicense: "cc" };
      instance.setState(state);
      equal(instance.value().ccLicense, state.ccLicense);
    });

    it("does not have ccLicense if usage right is not creative commons", () => {
      const state = { usageRight: "own_copyright", ccLicense: "cc" };
      instance.setState(state);
      ok(!instance.value().ccLicense);
    });
  });
});
