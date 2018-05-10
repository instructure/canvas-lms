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
import Folder from "./Folder";
import { css } from "aphrodite";
import styles from "./styles";

const DOWN_KEY = 40;
const UP_KEY = 38;
const J_KEY = 74;
const K_KEY = 75;

export default class FileTree extends Component {
  handleKeyDown = event => {
    switch (event.keyCode) {
      case DOWN_KEY:
      case J_KEY:
        this.moveFocus(1);
        break;
      case UP_KEY:
      case K_KEY:
        this.moveFocus(-1);
        break;
      default:
        return;
    }
    event.stopPropagation();
  };

  navigableNodes() {
    return Array.from(this.containerNode.querySelectorAll("button"));
  }

  moveFocus(delta) {
    const nodes = this.navigableNodes();
    const active = nodes.indexOf(window.document.activeElement);
    let next = active + delta;
    if (next < 0) {
      next = 0;
    } else if (next >= nodes.length) {
      next = nodes.length - 1;
    }
    nodes[next].focus();
  }

  render() {
    const inlineStyles = {
      maxHeight: this.props.maxHeight
    };
    return (
      <div
        className={css(styles.container)}
        ref={c => (this.containerNode = c)}
        onKeyDown={this.handleKeyDown}
        style={inlineStyles}
      >
        <Folder {...this.props} />
      </div>
    );
  }
}

FileTree.propTypes = {
  ...Folder.propTypes,
  maxHeight: PropTypes.string
};
