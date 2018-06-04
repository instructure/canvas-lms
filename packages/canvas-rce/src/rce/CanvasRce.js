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
import RCEWrapper from "./RCEWrapper";
import tinyRCE from "./tinyRCE";
import normalizeProps from "./normalizeProps";
import formatMessage from "../format-message";
import Bridge from "../bridge";
import skin from "tinymce-light-skin";

export default class CanvasRce extends Component {
  static propTypes = {
    skin: PropTypes.object,
    rceProps: PropTypes.object,
    renderCallback: PropTypes.func,
    // rcePropsToggle forces the component to re-evaulate rceProps when changed
    // Without it, the component cannot recognize changes to editorOptions
    rcePropsToggle: PropTypes.bool
  };

  componentWillMount() {
    if (!this.props.skin) {
      skin.useCanvas();
    }
    tinyRCE.DOM.loadCSS = () => {};
    this.normalizedProps = normalizeProps(this.props.rceProps, tinyRCE);
    formatMessage.setup({ locale: this.normalizedProps.language });
  }

  componentDidMount() {
    Bridge.renderEditor(this.rce);
    this.props.renderCallback && this.props.renderCallback(this.rce);
  }

  componentWillUpdate(nextProps) {
    if (this.props.rcePropsToggle !== nextProps.rcePropsToggle) {
      this.normalizedProps = normalizeProps(nextProps.rceProps, tinyRCE);
    }
  }

  render() {
    return (
      <RCEWrapper {...this.normalizedProps} ref={node => (this.rce = node)} />
    );
  }
}
