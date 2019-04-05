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

import React, {Component} from 'react'
import {array, bool, func, shape} from 'prop-types'

import LoadMore from '../../../../common/components/LoadMore'
import Image from './Image'

export default class ImageList extends Component {
  componentWillMount() {
    this.props.fetchImages({calledFromRender: true})
  }

  render() {
    return (
      <div style={{maxHeight: '300px', overflow: 'auto'}}>
        <div style={{clear: 'both'}}>
          <LoadMore
            focusSelector=".img_link"
            hasMore={this.props.images.hasMore}
            isLoading={this.props.images.isLoading}
            loadMore={this.props.fetchImages}
          >
            <div style={{width: '100%'}}>
              {this.props.images.records.map(image => (
                <Image
                  image={image}
                  key={'image-' + image.id}
                  onImageEmbed={this.props.onImageEmbed}
                />
              ))}
            </div>
          </LoadMore>
        </div>
      </div>
    )
  }
}

ImageList.propTypes = {
  fetchImages: func.isRequired,
  images: shape({
    records: array.isRequired,
    isLoading: bool.isRequired,
    hasMore: bool.isRequired
  }),
  onImageEmbed: func.isRequired
}

ImageList.defaultProps = {
  images: []
}
