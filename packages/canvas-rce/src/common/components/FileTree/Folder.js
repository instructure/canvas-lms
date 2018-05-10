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
import File from "./File";
import Loading from "../Loading";
import { css } from "aphrodite";
import styles from "./styles";
import IconMiniArrowDownLine from "@instructure/ui-icons/lib/Line/IconMiniArrowDown";
import IconMiniArrowRightLine from "@instructure/ui-icons/lib/Line/IconMiniArrowRight";
import IconFolderLine from "@instructure/ui-icons/lib/Line/IconFolder";

export default class Folder extends Component {
  handleToggle = () => {
    const { onToggle, folder } = this.props;
    if (onToggle) {
      onToggle(folder.id);
    }
  };

  files() {
    return this.props.folder.fileIds
      .map(id => this.props.files[id])
      .filter(file => file != null);
  }

  subFolders() {
    return this.props.folder.folderIds
      .map(id => this.props.folders[id])
      .filter(folder => folder != null);
  }

  toggleIcon() {
    const { expanded } = this.props.folder;
    return expanded ? <IconMiniArrowDownLine /> : <IconMiniArrowRightLine />;
  }

  render() {
    const { folders, folder, files, onSelect, onToggle } = this.props;
    return (
      <div className={css(styles.node)}>
        <button
          className={css(styles.button)}
          onClick={this.handleToggle}
          aria-expanded={!!folder.expanded}
        >
          {this.toggleIcon()} <IconFolderLine /> {folder.name}
        </button>

        {folder.expanded && (
          <ul className={css(styles.list)}>
            {this.subFolders().map(folder => (
              <li key={`folder-${folder.id}`} className={css(styles.node)}>
                <Folder
                  folders={folders}
                  files={files}
                  folder={folder}
                  onToggle={onToggle}
                  onSelect={onSelect}
                />
              </li>
            ))}
            {this.files().map(file => (
              <li key={`file-${file.id}`} className={css(styles.node)}>
                <File onSelect={onSelect} file={file} />
              </li>
            ))}
          </ul>
        )}

        {folder.expanded &&
          folder.loading && <Loading className={css(styles.loading)} />}
      </div>
    );
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
