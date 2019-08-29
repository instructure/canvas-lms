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

import PropTypes from "prop-types";

import React, { Component } from "react";
import { Checkbox, TextInput } from '@instructure/ui-forms'
import {View} from "@instructure/ui-layout";
import formatMessage from "../../format-message";
import { ScreenReaderContent } from '@instructure/ui-a11y'

export default class AltTextForm extends Component {
  static propTypes = {
    altResolved: PropTypes.func.isRequired
  };

  handleAltTextChange = e => {
    const state = { ...this.state, altText: e.target.value };
    this.setState(state);
    this.props.altResolved(this.isAltResolved(state));
  };

  handleDecorativeCheckbox = e => {
    const state = { ...this.state, decorativeSelected: e.target.checked };
    this.setState(state);
    this.props.altResolved(this.isAltResolved(state));
  };

  state = {
    altText: "",
    decorativeSelected: false
  };

  componentDidMount() {
    this.altTextField.focus();
  }

  isAltResolved(state) {
    return state.decorativeSelected || state.altText.length > 0;
  }

  value() {
    return this.state;
  }

  render() {
    const altScreenreaderMessage = formatMessage(
      "Enter the alternative text for this image"
    );
    const altLabelText = formatMessage("Alternative text:");
    const alt_label = (
      <span>
        <span aria-hidden>{altLabelText}</span>
        <ScreenReaderContent>{altScreenreaderMessage}</ScreenReaderContent>
      </span>
    );
    const decorativeScreenreaderMessage = formatMessage(
      "Check if the image is decorative"
    );
    const decorativeLabelText = formatMessage("Decorative image");
    const decorative_label = (
      <span>
        <span aria-hidden>{decorativeLabelText}</span>
        <ScreenReaderContent>
          {decorativeScreenreaderMessage}
        </ScreenReaderContent>
      </span>
    );
    return (
      <div className="rcs-AltTextForm">
        <TextInput
          ref={input => {
            this.altTextField = input;
          }}
          label={alt_label}
          onChange={this.handleAltTextChange}
          name="alt_text"
          disabled={this.state.decorativeSelected}
        />
        <View margin="x-small 0" display="block">
          <Checkbox
            label={decorative_label}
            name="decorative"
            onChange={this.handleDecorativeCheckbox}
          />
        </View>
      </div>
    );
  }
}
