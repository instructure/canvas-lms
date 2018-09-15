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
import ReactCSSTransitionGroup from "react-transition-group/CSSTransitionGroup";
import formatMessage from "../../format-message";
import ScreenReaderContent from "@instructure/ui-a11y/lib/components/ScreenReaderContent";
import Select from "@instructure/ui-core/lib/components/Select";
import Button from "@instructure/ui-buttons/lib/components/Button";
import Alert from "@instructure/ui-alerts/lib/components/Alert";
import IconAddSolid from "@instructure/ui-icons/lib/Solid/IconAdd";
import IconMinimizeSolid from "@instructure/ui-icons/lib/Solid/IconMinimize";
import Loading from "../../common/components/Loading";
import UsageRightsForm from "./UsageRightsForm";
import AltTextForm from "./AltTextForm";
import { StyleSheet, css } from "aphrodite";

class UploadForm extends Component {
  constructor(props) {
    super(props);
    this.state = { file: {}, altResolved: false };
  }

  componentWillMount() {
    if (this.props.fetchFolders) {
      this.props.fetchFolders();
    }
  }

  flattenFolderTreeDepthFirst(folderId, folderTree, accum, depth) {
    if (!folderId) {
      return [];
    }
    accum = accum || [];
    depth = depth || 0;
    accum.push({ folderId, depth });
    if (!folderTree[folderId]) {
      return accum;
    }
    folderTree[folderId].forEach(sfId => {
      this.flattenFolderTreeDepthFirst(sfId, folderTree, accum, depth + 1);
    });
    return accum;
  }

  parentFolderId() {
    let stateId = this.state.file.parentFolderId;
    if (stateId) {
      return stateId;
    }
    let firstKey = Object.keys(this.props.upload.folders)[0];
    let firstFolder = this.props.upload.folders[firstKey];
    if (firstFolder) {
      return firstFolder.id;
    }
    return null;
  }

  showForm(e) {
    e.preventDefault();
    this.props.toggleUploadForm();
    this.setState({ file: {} });
  }

  handleUpload(e) {
    e.preventDefault();
    let fileMetaProps = { ...this.state.file };
    if (this._usageRights) {
      fileMetaProps.usageRights = this._usageRights.value();
    }
    if (this._altText) {
      fileMetaProps.altText = this._altText.value();
    }
    this.props.startUpload(fileMetaProps);
  }

  handleFolderChange(e) {
    e.preventDefault();
    this.setState({
      file: {
        parentFolderId: e.target.value,
        name: this.state.file.name,
        size: this.state.file.size,
        contentType: this.state.file.contentType,
        domObject: this.state.file.domObject
      }
    });
  }

  handleFileClick(e) {
    e.target.value = "";
    this.setState({ file: { parentFolderId: this.parentFolderId() } });
  }

  handleFileChange(e) {
    var file = e.target.files[0];
    let fileStateUpdate = { file: {} };
    if (file !== undefined) {
      fileStateUpdate = {
        file: {
          parentFolderId: this.parentFolderId(),
          name: file.name,
          size: file.size,
          contentType: file.type,
          domObject: file
        }
      };
    }
    this.setState(fileStateUpdate);
  }

  isImageSelected(file) {
    return file && file.name;
  }

  uploadLink() {
    let screenreaderMessage = this.props.messages.expandScreenreader;
    let message = this.props.messages.expand;
    let icon;
    if (this.props.upload.formExpanded) {
      screenreaderMessage = this.props.messages.collapseScreenreader;
      message = this.props.messages.collapse;
      icon = <IconMinimizeSolid className={css(styles.icon)} />;
    } else {
      icon = <IconAddSolid className={css(styles.icon)} />;
    }

    return (
      <Button
        aria-expanded={this.props.upload.formExpanded}
        variant="link"
        onClick={this.showForm.bind(this)}
      >
        <span aria-hidden={true}>
          {icon}
          {" " + message}
        </span>
        <ScreenReaderContent>{screenreaderMessage}</ScreenReaderContent>
      </Button>
    );
  }

  renderFolderOption({ folderId, depth }) {
    let folder = this.props.upload.folders[folderId];
    if (!folder) {
      return;
    }

    let space = "";
    for (let i = 0; i < depth; i++) {
      space += "\u00A0\u00A0";
    }
    return (
      <option key={"folder_" + folder.id} value={folder.id}>
        {space}
        {folder.name}
      </option>
    );
  }

  renderFolderSelect() {
    let screenreaderMessage = formatMessage(
      "Select a folder to upload your file into"
    );
    let labelText = formatMessage("Folder");
    let label = (
      <span>
        <span aria-hidden={true}>{labelText}</span>
        <ScreenReaderContent>{screenreaderMessage}</ScreenReaderContent>
      </span>
    );
    let flattenedFolders = this.flattenFolderTreeDepthFirst(
      this.props.upload.rootFolderId,
      this.props.upload.folderTree
    );
    return (
      <Select
        label={label}
        onChange={this.handleFolderChange.bind(this)}
        name="folder_id"
      >
        {
          this.props.upload.loadingFolders && (
            <option key="loading" value="loading">
              {formatMessage("Loading folders...")}
            </option>
          )
        }
        {flattenedFolders.map(this.renderFolderOption, this)}
      </Select>
    );
  }

  shouldDisableUpload(props, state) {
    let ret;
    if (props.showAltTextForm) {
      ret = !(state.file && state.file.name && state.altResolved);
    } else {
      ret = !(state.file && state.file.name);
    }
    return ret;
  }

  renderFormSubmit() {
    if (this.props.upload.uploading) {
      return <Loading />;
    } else {
      return (
        <div className={css(styles.uploadButtonContainer)}>
          <Button
            type="submit"
            disabled={this.shouldDisableUpload(this.props, this.state)}
          >
            {formatMessage("Upload")}
          </Button>
        </div>
      );
    }
  }

  setAltResolved = resolved => {
    this.setState({ ...this.state, altResolved: resolved });
  };

  renderForm() {
    if (this.props.upload.formExpanded) {
      let screenreaderMessage = formatMessage("Select a file");
      let errorMessage =
        this.props.upload.error &&
        this.props.upload.error.type === "QUOTA_EXCEEDED_UPLOAD"
          ? formatMessage(
              "This upload exceeds the file storage quota. Please speak to your system administrator."
            )
          : null;
      return (
        <form
          onSubmit={this.handleUpload.bind(this)}
          className={css(styles.uploadForm)}
          encType="multipart/form-data"
        >
          <div>
            <div className={css(styles.uploadLimit)}>
              <label htmlFor="upload-form-file-input">
                <ScreenReaderContent>{screenreaderMessage}</ScreenReaderContent>
              </label>
              {errorMessage && <Alert variant="error">{errorMessage}</Alert>}
              <input
                className={css(styles.uploadedData)}
                type="file"
                onChange={this.handleFileChange.bind(this)}
                onClick={this.handleFileClick.bind(this)}
                style={{ width: "100%" }}
              />
            </div>
            {this.props.showAltTextForm &&
              this.isImageSelected(this.state.file) && (
                <AltTextForm
                  ref={ref => (this._altText = ref)}
                  altResolved={this.setAltResolved}
                />
              )}
            {this.renderFolderSelect()}
            {this.props.usageRightsRequired && (
              <UsageRightsForm ref={ref => (this._usageRights = ref)} />
            )}
          </div>
          {this.renderFormSubmit()}
        </form>
      );
    }
    return null;
  }

  render() {
    return (
      <div className={css(styles.container)}>
        {this.uploadLink()}
        <ReactCSSTransitionGroup
          transitionName={{
            enter: css(styles.slideDownEnter),
            enterActive: css(
              styles.slideDownEnter,
              styles.slideDownEnterActive
            ),
            leave: css(styles.slideDownLeave),
            leaveActive: css(styles.slideDownLeave, styles.slideDownLeaveActive)
          }}
          transitionEnterTimeout={500}
          transitionLeaveTimeout={300}
        >
          {this.renderForm()}
        </ReactCSSTransitionGroup>
      </div>
    );
  }
}

UploadForm.propTypes = {
  upload: PropTypes.shape({
    loading: PropTypes.bool,
    folders: PropTypes.objectOf(
      PropTypes.shape({
        id: PropTypes.number,
        name: PropTypes.string,
        parentId: PropTypes.number
      })
    ).isRequired,
    uploading: PropTypes.bool.isRequired,
    formExpanded: PropTypes.bool.isRequired,
    rootFolderId: PropTypes.number,
    folderTree: PropTypes.object.isRequired,
    error: PropTypes.shape({
      type: PropTypes.string
    })
  }).isRequired,
  toggleUploadForm: PropTypes.func.isRequired,
  fetchFolders: PropTypes.func.isRequired,
  startUpload: PropTypes.func.isRequired,
  usageRightsRequired: PropTypes.bool,
  messages: PropTypes.shape({
    expand: PropTypes.string.isRequired,
    expandScreenreader: PropTypes.string.isRequired,
    collapse: PropTypes.string.isRequired,
    collapseScreenreader: PropTypes.string.isRequired
  }).isRequired,
  showAltTextForm: PropTypes.bool.isRequired
};

export const styles = StyleSheet.create({
  slideDownEnter: {
    maxHeight: 0,
    overflowY: "hidden"
  },
  slideDownEnterActive: {
    maxHeight: "500px",
    transition: "max-height 500ms ease-in"
  },
  slideDownLeave: {
    maxHeight: "500px",
    overflowY: "hidden"
  },
  slideDownLeaveActive: {
    maxHeight: 0,
    transition: "max-height 300ms ease-in"
  },
  container: {
    marginTop: "10px"
  },
  uploadForm: {
    marginTop: "6px",
    lineHeight: 1.5,
    maxWidth: "100%"
  },
  uploadLimit: {
    fontSize: "11px",
    margin: "10px 0 1em",
    display: "block"
  },
  uploadButtonContainer: {
    marginTop: "0.5em"
  },
  uploadedData: {
    display: "block",
    marginBottom: "10px"
  },
  folderId: {
    marginBottom: "10px"
  },
  icon: {
    verticalAlign: "middle"
  }
});

export default UploadForm;
