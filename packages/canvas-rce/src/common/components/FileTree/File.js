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
import { number, string, shape, func } from "prop-types";
import { css } from "aphrodite";
import styles from "./styles";
import IconDocumentLine from "@instructure/ui-icons/lib/Line/IconDocument";

export default class File extends Component {
  handleSelect = () => {
    const { onSelect, file } = this.props;
    if (onSelect) {
      onSelect(file.id);
    }
  };

  icon() {
    switch (this.props.file.type) {
      default:
        return <IconDocumentLine />;
    }
  }

  render() {
    const { name } = this.props.file;
    return (
      <button
        className={css(styles.button, styles.file)}
        onClick={this.handleSelect}
      >
        {this.icon()} {name}
      </button>
    );
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
