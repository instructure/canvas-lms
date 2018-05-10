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
import FileTree from "../../common/components/FileTree";
import formatMessage from "../../format-message";
import UploadForm from "./UploadForm";

export default class FilesPanel extends Component {
  handleSelect = id => {
    const file = this.props.files[id];
    this.props.onLinkClick({
      title: file.name,
      href: file.url,
      embed: file.embed
    });
  };

  renderUploadForm() {
    if (this.props.withUploadForm) {
      return (
        <UploadForm
          fetchFolders={this.props.fetchFolders}
          upload={this.props.upload}
          toggleUploadForm={this.props.toggleUploadForm}
          startUpload={this.props.startUpload}
          usageRightsRequired={this.props.usageRightsRequired}
          messages={{
            expand: formatMessage("Upload a new file"),
            expandScreenreader: formatMessage("File Upload Form"),
            collapse: formatMessage("Cancel file upload"),
            collapseScreenreader: formatMessage("File Upload Form")
          }}
          showAltTextForm={false}
        />
      );
    }
    return null;
  }

  render() {
    return (
      <div>
        <p>
          {formatMessage(
            "Click any file to insert a download link for that file."
          )}
        </p>
        {this.props.rootFolderId != null && (
          <FileTree
            onSelect={this.handleSelect}
            onToggle={this.props.toggleFolder}
            files={this.props.files}
            folders={this.props.folders}
            folder={this.props.folders[this.props.rootFolderId]}
            maxHeight="37em"
          />
        )}
        {this.renderUploadForm()}
      </div>
    );
  }
}

FilesPanel.propTypes = {
  withUploadForm: PropTypes.bool,
  files: PropTypes.objectOf(
    PropTypes.shape({
      id: PropTypes.number,
      name: PropTypes.string,
      type: PropTypes.string,
      url: PropTypes.string
    })
  ),
  folders: PropTypes.objectOf(
    PropTypes.shape({
      id: PropTypes.number,
      name: PropTypes.string,
      filesUrl: PropTypes.string,
      foldersUrl: PropTypes.string
    })
  ),
  rootFolderId: PropTypes.number,
  toggleFolder: PropTypes.func.isRequired,
  fetchFolders: UploadForm.propTypes.fetchFolders,
  startUpload: UploadForm.propTypes.startUpload,
  upload: UploadForm.propTypes.upload,
  toggleUploadForm: UploadForm.propTypes.toggleUploadForm,
  onLinkClick: PropTypes.func.isRequired,
  canUploadFiles: PropTypes.bool,
  usageRightsRequired: PropTypes.bool
};
