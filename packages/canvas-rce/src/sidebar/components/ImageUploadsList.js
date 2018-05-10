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
import LoadMore from "../../common/components/LoadMore";
import UploadedImage from "./UploadedImage";

class ImageUploadsList extends Component {
  componentWillMount() {
    var fetchEvent = { calledFromRender: true };
    this.props.fetchImages(fetchEvent);
  }

  renderImages() {
    return (
      <div style={{ width: "100%" }}>
        {this.props.images.records.map(image => {
          return (
            <UploadedImage
              key={"image-" + image.id}
              image={image}
              onImageEmbed={this.props.onImageEmbed}
            />
          );
        })}
      </div>
    );
  }

  render() {
    return (
      <div style={{ maxHeight: "300px", overflow: "auto" }}>
        <div style={{ clear: "both" }}>
          <LoadMore
            focusSelector=".img_link"
            hasMore={this.props.images.hasMore}
            isLoading={this.props.images.isLoading}
            loadMore={this.props.fetchImages}
          >
            {this.renderImages()}
          </LoadMore>
        </div>
      </div>
    );
  }
}

ImageUploadsList.propTypes = {
  images: PropTypes.shape({
    records: PropTypes.array.isRequired,
    isLoading: PropTypes.bool.isRequired,
    hasMore: PropTypes.bool.isRequired
  }),
  fetchImages: PropTypes.func.isRequired,
  onImageEmbed: PropTypes.func.isRequired
};

ImageUploadsList.defaultProps = {
  images: []
};

export default ImageUploadsList;
