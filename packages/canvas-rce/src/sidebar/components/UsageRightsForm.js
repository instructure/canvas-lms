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

import React, { Component } from "react";
import formatMessage from "../../format-message";
import Select from "@instructure/ui-core/lib/components/Select";
import TextInput from "@instructure/ui-core/lib/components/TextInput";
import Alert from "@instructure/ui-core/lib/components/Alert";

const usageRightsValues = {
  "": formatMessage("Choose usage rights..."),
  own_copyright: formatMessage("I hold the copyright"),
  used_by_permission: formatMessage(
    "I have obtained permission to use this file."
  ),
  public_domain: formatMessage("The material is in the public domain"),
  fair_use: formatMessage("The material is subject to fair use exception"),
  creative_commons: formatMessage(
    "The material is licensed under Creative Commons"
  )
};

// Note: These are hard-coded here to avoid making an additional API call to
// get the hard-coded list from the server. This will need to change if the
// license options become more dynamic in the future.
const creativeCommonsLicenses = {
  cc_by_nc_nd: formatMessage("CC Attribution Non-Commercial No Derivatives"),
  cc_by_nc_sa: formatMessage("CC Attribution Non-Commercial Share Alike"),
  cc_by_nc: formatMessage("CC Attribution Non-Commercial"),
  cc_by_nd: formatMessage("CC Attribution No Derivatives"),
  cc_by_sa: formatMessage("CC Attribution Share Alike"),
  cc_by: formatMessage("CC Attribution")
};

export default class UsageRightsForm extends Component {
  constructor() {
    super();
    this.state = {
      usageRight: Object.keys(usageRightsValues)[0],
      copyrightHolder: ""
    };
    this.handleUsageRight = this.handleUsageRight.bind(this);
    this.handleCCLicense = this.handleCCLicense.bind(this);
    this.handleCopyrightHolder = this.handleCopyrightHolder.bind(this);
  }

  isCreativeCommons() {
    return this.state.usageRight === "creative_commons";
  }

  isNotSelected() {
    return this.state.usageRight === Object.keys(usageRightsValues)[0];
  }

  handleUsageRight(ev) {
    this.setState({ usageRight: ev.target.value });
  }

  handleCCLicense(ev) {
    this.setState({ ccLicense: ev.target.value });
  }

  handleCopyrightHolder(ev) {
    this.setState({ copyrightHolder: ev.target.value });
  }

  value() {
    if (this.isNotSelected()) {
      return null;
    }
    const state = { ...this.state };
    if (!this.isCreativeCommons()) {
      delete state.ccLicense;
    }
    return state;
  }

  render() {
    return (
      <div className="rcs-UsageRightsForm">
        <Select
          label={formatMessage("Usage Right:")}
          value={this.state.usageRight}
          onChange={this.handleUsageRight}
        >
          {Object.keys(usageRightsValues).map(key => (
            <option key={key} value={key}>
              {usageRightsValues[key]}
            </option>
          ))}
        </Select>

        {this.isCreativeCommons() && (
          <Select
            label={formatMessage("Creative Commons License:")}
            value={this.state.ccLicense}
            onChange={this.handleCCLicense}
          >
            {Object.keys(creativeCommonsLicenses).map(key => (
              <option key={key} value={key}>
                {creativeCommonsLicenses[key]}
              </option>
            ))}
          </Select>
        )}

        <TextInput
          label={formatMessage("Copyright Holder:")}
          placeholder={formatMessage("(c) 2001 Acme Inc.")}
          value={this.state.copyrightHolder}
          onChange={this.handleCopyrightHolder}
        />

        {this.isNotSelected() && (
          <Alert variant="warning">
            <i className="icon-warning" />
            {" " +
              formatMessage(
                "If you do not select usage rights now, this file will be unpublished after it's uploaded."
              )}
          </Alert>
        )}
      </div>
    );
  }
}
