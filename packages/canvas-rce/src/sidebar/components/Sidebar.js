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
import TabList from "@instructure/ui-tabs/lib/components/TabList";
import TabPanel from "@instructure/ui-tabs/lib/components/TabList/TabPanel";
import Tab from "@instructure/ui-core/lib/components/TabList/Tab";
import ApplyTheme from "@instructure/ui-themeable/lib/components/ApplyTheme";
import LinksPanel from "./LinksPanel";
import FilesPanel from "./FilesPanel";
import ImagesPanel from "./ImagesPanel";
import formatMessage from "../../format-message";
import UploadForm from "./UploadForm";

class Sidebar extends Component {
  disableFilesPanel() {
    return (
      Object.keys(this.props.folders).length === 0 &&
      Object.keys(this.props.files).length === 0
    );
  }

  render() {
    if (this.props.hidden) {
      return <div style={{ display: "none" }} />;
    }

    const linksTitle = formatMessage({
      default: "Links",
      description: "Title of Sidebar tab containing links to course pages."
    });
    const filesTitle = formatMessage({
      default: "Files",
      description: "Title of Sidebar tab containing uploaded files."
    });
    const imagesTitle = formatMessage({
      default: "Images",
      description:
        "Title of Sidebar tab containing uploaded images and image services."
    });

    return (
      <ApplyTheme theme={{ [Tab.theme]: { fontSize: "0.8125rem" } }}>
        <TabList
          selectedIndex={this.props.selectedTabIndex}
          onChange={this.props.onChangeTab}
        >
          <TabPanel title={linksTitle}>
            <LinksPanel
              selectedIndex={this.props.selectedAccordionIndex}
              onChange={this.props.onChangeAccordion}
              fetchInitialPage={this.props.fetchInitialPage}
              fetchNextPage={this.props.fetchNextPage}
              contextType={this.props.contextType}
              contextId={this.props.contextId}
              collections={this.props.collections}
              onLinkClick={this.props.onLinkClick}
              toggleNewPageForm={this.props.toggleNewPageForm}
              newPageLinkExpanded={this.props.newPageLinkExpanded}
              canCreatePages={this.props.session.canCreatePages}
            />
          </TabPanel>
          <TabPanel title={filesTitle} disabled={this.disableFilesPanel()}>
            <FilesPanel
              withUploadForm={this.props.canUploadFiles}
              files={this.props.files}
              folders={this.props.folders}
              fetchFolders={this.props.fetchFolders}
              rootFolderId={this.props.rootFolderId}
              startUpload={this.props.startUpload.bind(null, "files")}
              onLinkClick={this.props.onLinkClick}
              toggleFolder={this.props.toggleFolder}
              upload={this.props.upload}
              toggleUploadForm={this.props.toggleUploadForm}
              canUploadFiles={this.props.session.canUploadFiles}
              usageRightsRequired={this.props.session.usageRightsRequired}
            />
          </TabPanel>
          <TabPanel id="ImagesSidebarPanel" title={imagesTitle}>
            <ImagesPanel
              withUploadForm={this.props.canUploadFiles}
              upload={this.props.upload}
              images={this.props.images}
              startUpload={this.props.startUpload.bind(null, "images")}
              fetchFolders={this.props.fetchFolders}
              fetchImages={this.props.fetchImages}
              flickr={this.props.flickr}
              flickrSearch={this.props.flickrSearch}
              toggleUploadForm={this.props.toggleUploadForm}
              toggleFlickrForm={this.props.toggleFlickrForm}
              onImageEmbed={this.props.onImageEmbed}
              usageRightsRequired={this.props.session.usageRightsRequired}
            />
          </TabPanel>
        </TabList>
      </ApplyTheme>
    );
  }
}

Sidebar.propTypes = {
  hidden: PropTypes.bool,
  selectedTabIndex: PropTypes.number,
  onChangeTab: PropTypes.func,
  selectedAccordionIndex: PropTypes.string,
  onChangeAccordion: PropTypes.func,
  contextType: PropTypes.string.isRequired,
  contextId: PropTypes.string.isRequired,
  collections: PropTypes.object.isRequired,
  fetchInitialPage: PropTypes.func,
  fetchNextPage: PropTypes.func,
  onLinkClick: PropTypes.func,
  onImageEmbed: PropTypes.func,
  toggleFolder: FilesPanel.propTypes.toggleFolder,
  files: FilesPanel.propTypes.files,
  folders: FilesPanel.propTypes.folders,
  rootFolderId: FilesPanel.propTypes.rootFolderId,
  images: ImagesPanel.propTypes.images,
  flickr: ImagesPanel.propTypes.flickr,
  fetchImages: ImagesPanel.propTypes.fetchImages,
  fetchFolders: ImagesPanel.propTypes.fetchFolders,
  flickrSearch: ImagesPanel.propTypes.flickrSearch,
  canUploadFiles: ImagesPanel.propTypes.withUploadForm,
  toggleFlickrForm: ImagesPanel.propTypes.toggleFlickrForm,
  upload: UploadForm.propTypes.upload,
  startUpload: UploadForm.propTypes.startUpload,
  toggleUploadForm: UploadForm.propTypes.toggleUploadForm,
  session: PropTypes.shape({
    canUploadFiles: PropTypes.bool,
    usageRightsRequired: PropTypes.bool,
    useHighContrast: PropTypes.bool,
    canCreatePages: PropTypes.bool
  }),
  toggleNewPageForm: LinksPanel.propTypes.toggleNewPageForm,
  newPageLinkExpanded: PropTypes.bool
};

Sidebar.defaultProps = {
  hidden: false,
  selectedTabIndex: 0,
  selectedAccordionIndex: "",
  canUploadFiles: false,
  files: {},
  folders: {}
};

export default Sidebar;
