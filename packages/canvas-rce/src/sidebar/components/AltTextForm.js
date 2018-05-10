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
import Checkbox from "@instructure/ui-forms/lib/components/Checkbox";
import Container from "@instructure/ui-layout/lib/components/View";
import TextInput from "@instructure/ui-forms/lib/components/TextInput";
import formatMessage from "../../format-message";
import ScreenReaderContent from "@instructure/ui-a11y/lib/components/ScreenReaderContent";

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
    let altScreenreaderMessage = formatMessage(
      "Enter the alternative text for this image"
    );
    let altLabelText = formatMessage("Alternative text:");
    let alt_label = (
      <span>
        <span aria-hidden={true}>{altLabelText}</span>
        <ScreenReaderContent>{altScreenreaderMessage}</ScreenReaderContent>
      </span>
    );
    let decorativeScreenreaderMessage = formatMessage(
      "Check if the image is decorative"
    );
    let decorativeLabelText = formatMessage("Decorative image");
    let decorative_label = (
      <span>
        <span aria-hidden={true}>{decorativeLabelText}</span>
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
        <Container margin="x-small 0" display="block">
          <Checkbox
            label={decorative_label}
            name="decorative"
            onChange={this.handleDecorativeCheckbox}
          />
        </Container>
      </div>
    );
  }
}
