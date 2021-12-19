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
import PropTypes from 'prop-types';
import React, { Component } from 'react';
import File from "./File.js";
import Loading from "../Loading.js";
import { css } from 'aphrodite';
import styles from "./styles.js";
import { IconMiniArrowDownLine, IconMiniArrowEndLine, IconFolderLine } from '@instructure/ui-icons';
export default class Folder extends Component {
  constructor(...args) {
    super(...args);

    this.handleToggle = () => {
      const _this$props = this.props,
            onToggle = _this$props.onToggle,
            folder = _this$props.folder;

      if (onToggle) {
        onToggle(folder.id);
      }
    };
  }

  files() {
    return this.props.folder.fileIds.map(id => this.props.files[id]).filter(file => file != null);
  }

  subFolders() {
    return this.props.folder.folderIds.map(id => this.props.folders[id]).filter(folder => folder != null);
  }

  toggleIcon() {
    const expanded = this.props.folder.expanded;
    return expanded ? /*#__PURE__*/React.createElement(IconMiniArrowDownLine, null) : /*#__PURE__*/React.createElement(IconMiniArrowEndLine, null);
  }

  render() {
    const _this$props2 = this.props,
          folders = _this$props2.folders,
          folder = _this$props2.folder,
          files = _this$props2.files,
          onSelect = _this$props2.onSelect,
          onToggle = _this$props2.onToggle;
    return /*#__PURE__*/React.createElement("div", {
      className: css(styles.node)
    }, /*#__PURE__*/React.createElement("button", {
      className: css(styles.button),
      onClick: this.handleToggle,
      "aria-expanded": !!folder.expanded
    }, this.toggleIcon(), " ", /*#__PURE__*/React.createElement(IconFolderLine, null), " ", folder.name), folder.expanded && /*#__PURE__*/React.createElement("ul", {
      className: css(styles.list)
    }, this.subFolders().map(folder => /*#__PURE__*/React.createElement("li", {
      key: `folder-${folder.id}`,
      className: css(styles.node)
    }, /*#__PURE__*/React.createElement(Folder, {
      folders: folders,
      files: files,
      folder: folder,
      onToggle: onToggle,
      onSelect: onSelect
    }))), this.files().map(file => /*#__PURE__*/React.createElement("li", {
      key: `file-${file.id}`,
      className: css(styles.node)
    }, /*#__PURE__*/React.createElement(File, {
      onSelect: onSelect,
      file: file
    })))), folder.expanded && folder.loading && /*#__PURE__*/React.createElement(Loading, {
      className: css(styles.loading)
    }));
  }

}
const folderPropType = PropTypes.shape({
  id: PropTypes.number,
  name: PropTypes.string,
  loading: PropTypes.bool,
  fileIds: PropTypes.arrayOf(PropTypes.number),
  folderIds: PropTypes.arrayOf(PropTypes.number)
});
Folder.propTypes = {
  folders: PropTypes.objectOf(folderPropType),
  files: PropTypes.objectOf(File.propTypes.file),
  folder: folderPropType.isRequired,
  onToggle: PropTypes.func,
  onSelect: File.propTypes.onSelect
};
Folder.defaultProps = {
  files: [],
  folders: []
};