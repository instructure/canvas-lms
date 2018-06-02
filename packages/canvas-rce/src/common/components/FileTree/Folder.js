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
import File from "./File";
import Loading from "../Loading";
import { css } from "aphrodite";
import styles from "./styles";
import IconMiniArrowDownLine from "instructure-icons/lib/Line/IconMiniArrowDownLine";
import IconMiniArrowRightLine from "instructure-icons/lib/Line/IconMiniArrowRightLine";
import IconFolderLine from "instructure-icons/lib/Line/IconFolderLine";

export default class Folder extends Component {
  constructor(props) {
    super(props);
    this.handleToggle = this.handleToggle.bind(this);
  }

  handleToggle() {
    const { onToggle, folder } = this.props;
    if (onToggle) {
      onToggle(folder.id);
    }
  }

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

const folderPropType = React.PropTypes.shape({
  id: React.PropTypes.number,
  name: React.PropTypes.string,
  loading: React.PropTypes.bool,
  fileIds: React.PropTypes.arrayOf(React.PropTypes.number),
  folderIds: React.PropTypes.arrayOf(React.PropTypes.number)
});

Folder.propTypes = {
  folders: React.PropTypes.objectOf(folderPropType),
  files: React.PropTypes.objectOf(File.propTypes.file),
  folder: folderPropType.isRequired,
  onToggle: React.PropTypes.func,
  onSelect: File.propTypes.onSelect
};

Folder.defaultProps = {
  files: [],
  folders: []
};
