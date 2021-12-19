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
import React, { Component } from 'react';
import { number, string, shape, func } from 'prop-types';
import { css } from 'aphrodite';
import styles from "./styles.js";
import { IconDocumentLine } from '@instructure/ui-icons';
export default class File extends Component {
  constructor(...args) {
    super(...args);

    this.handleSelect = () => {
      const _this$props = this.props,
            onSelect = _this$props.onSelect,
            file = _this$props.file;

      if (onSelect) {
        onSelect(file.id);
      }
    };
  }

  icon() {
    switch (this.props.file.type) {
      default:
        return /*#__PURE__*/React.createElement(IconDocumentLine, null);
    }
  }

  render() {
    const name = this.props.file.name;
    return /*#__PURE__*/React.createElement("button", {
      className: css(styles.button, styles.file),
      onClick: this.handleSelect
    }, this.icon(), " ", name);
  }

}
File.propTypes = {
  file: shape({
    id: number,
    name: string,
    type: string
  }).isRequired,
  onSelect: func
};