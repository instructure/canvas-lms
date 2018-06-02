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

import React, { Component, PropTypes } from "react";
import formatMessage from "../../format-message";
import UploadForm from "./UploadForm";
import ImageUploadsList from "./ImageUploadsList";
import FlickrSearch from "./FlickrSearch";

class ImagesPanel extends Component {
  instructions() {
    return (
      <p>{formatMessage("Click any image to embed the image in the page.")}</p>
    );
  }

  renderUploadForm() {
    if (this.props.withUploadForm) {
      return (
        <UploadForm
          fetchFolders={this.props.fetchFolders}
          upload={this.props.upload}
          toggleUploadForm={this.props.toggleUploadForm}
          startUpload={this.props.startUpload}
          onImageEmbed={this.props.onImageEmbed}
          usageRightsRequired={this.props.usageRightsRequired}
          messages={{
            expand: formatMessage("Upload a new image"),
            expandScreenreader: formatMessage("Image Upload Form"),
            collapse: formatMessage("Cancel image upload"),
            collapseScreenreader: formatMessage("Image Upload Form")
          }}
          showAltTextForm={true}
        />
      );
    }
    return null;
  }

  renderFlickrSearchForm() {
    return (
      <FlickrSearch
        flickrSearch={this.props.flickrSearch}
        toggleFlickrForm={this.props.toggleFlickrForm}
        flickr={this.props.flickr}
        onImageEmbed={this.props.onImageEmbed}
      />
    );
  }

  renderImageUploadsList() {
    return (
      <ImageUploadsList
        images={this.props.images}
        fetchImages={this.props.fetchImages}
        onImageEmbed={this.props.onImageEmbed}
      />
    );
  }

  render() {
    return (
      <div>
        {this.instructions()}
        {this.renderFlickrSearchForm()}
        {this.renderUploadForm()}
        {this.renderImageUploadsList()}
      </div>
    );
  }
}

ImagesPanel.propTypes = {
  withUploadForm: PropTypes.bool,
  upload: UploadForm.propTypes.upload,
  images: ImageUploadsList.propTypes.images,
  fetchImages: ImageUploadsList.propTypes.fetchImages,
  fetchFolders: UploadForm.propTypes.fetchFolders,
  startUpload: UploadForm.propTypes.startUpload,
  flickr: FlickrSearch.propTypes.flickr,
  flickrSearch: FlickrSearch.propTypes.flickrSearch,
  toggleFlickrForm: FlickrSearch.propTypes.toggleFlickrForm,
  toggleUploadForm: UploadForm.propTypes.toggleUploadForm,
  onImageEmbed: ImageUploadsList.propTypes.onImageEmbed,
  usageRightsRequired: PropTypes.bool
};

ImagesPanel.defaultProps = { withUploadForm: false };

export default ImagesPanel;
