/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import PropTypes from 'prop-types'

class ImageSearchItem extends React.Component {
  static propTypes = {
    description: PropTypes.string,
    src: PropTypes.string,
    confirmationId: PropTypes.string,
    selectImage: PropTypes.func
  }

  handleClick = () => {
    this.props.selectImage(this.props.src, this.props.confirmationId);
  }

  render () {
    return (
      <button className="ImageSearch__item"
              type="button"
              onClick={this.handleClick}
      >
        <img className="ImageSearch__display"
             alt={this.props.description}
             src={this.props.src}
        />
      </button>
    )
  }
}

export default ImageSearchItem
