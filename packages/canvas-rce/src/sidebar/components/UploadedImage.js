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
import { renderImage as renderImageHtml } from "../../rce/contentRendering";
import dragHtml from "../dragHtml";
import formatMessage from "../../format-message";

class UploadedImage extends Component {
  constructor(props) {
    super(props);
    this.onDrag = this.onDrag.bind(this);
    this.handleImageClick = this.handleImageClick.bind(this);
  }

  imgTitle() {
    return formatMessage("Click to embed { imageName }", {
      imageName: this.props.image.display_name
    });
  }

  handleImageClick(e) {
    e.preventDefault();
    this.props.onImageEmbed(this.props.image);
  }

  onDrag(ev) {
    dragHtml(ev, renderImageHtml(this.props.image));
  }

  renderImg() {
    let image = this.props.image;
    return (
      <img
        draggable={true}
        onDragStart={this.onDrag}
        src={image.thumbnail_url}
        alt={image.display_name}
        title={this.imgTitle()}
        style={{ maxHeight: 50, maxWidth: 200 }}
      />
    );
  }

  render() {
    let title = formatMessage("Click to embed image");
    return (
      <a
        href={this.props.image}
        role="button"
        title={title}
        draggable={false}
        onDragStart={this.onDrag}
        onClick={this.handleImageClick}
        style={imgLinkStyles}
      >
        <div style={{ minHeight: "50px" }}>{this.renderImg()}</div>
        <div style={{ wordBreak: "break-all" }}>
          {this.props.image.display_name}
        </div>
      </a>
    );
  }
}

UploadedImage.propTypes = {
  image: PropTypes.shape({
    id: PropTypes.number.isRequired,
    filename: PropTypes.string,
    display_name: PropTypes.string.isRequired,
    preview_url: PropTypes.string.isRequired,
    thumbnail_url: PropTypes.string,
    href: PropTypes.string
  }).isRequired,
  onImageEmbed: PropTypes.func.isRequired
};

const imgLinkStyles = {
  cursor: "pointer",
  overflow: "hidden",
  border: "1px solid #ccc",
  margin: "3px",
  padding: "3px",
  float: "left"
};

export default UploadedImage;
