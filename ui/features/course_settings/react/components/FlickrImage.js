/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'

class FlickrImage extends React.Component {
  handleClick = _event => {
    this.props.selectImage(this.props.url)
  }

  render() {
    const imageStyle = {
      backgroundImage: `url(${this.props.url})`,
    }

    return (
      <a className="FlickrImage" onClick={this.handleClick} href="javascript:;" ref="flickrImage">
        <img
          className="FlickrImage__screenreader"
          alt={this.props.searchTerm}
          src={this.props.url}
        />
        <div className="FlickrImage__display" style={imageStyle} />
      </a>
    )
  }
}

export default FlickrImage
