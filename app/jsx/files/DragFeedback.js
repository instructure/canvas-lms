/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import FilesystemObjectThumbnail from '../files/FilesystemObjectThumbnail'
import customPropTypes from 'compiled/react_files/modules/customPropTypes'

  var MAX_THUMBNAILS_TO_SHOW = 10;

  var DragFeedback = React.createClass({
    displayName: 'DragFeedback',

    propTypes: {
      itemsToDrag: PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired,
      pageX: PropTypes.number.isRequired,
      pageY: PropTypes.number.isRequired
    },

    render () {
      return (

        <div className='DragFeedback' style={{
          WebkitTransform: `translate3d(${this.props.pageX + 6}px, ${this.props.pageY + 6}px, 0)`,
          transform: `translate3d(${this.props.pageX + 6}px, ${this.props.pageY + 6}px, 0)`
        }}>

        {this.props.itemsToDrag.slice(0, MAX_THUMBNAILS_TO_SHOW).map((model, index) => {
          return (
            <FilesystemObjectThumbnail
              model={model}
              key={model.id}
              style={{
                left: 10 + index * 5 - index,
                top: 10 + index * 5 - index
              }}
            />
          );
        })}
        <span className='badge badge-important'>{this.props.itemsToDrag.length}</span>

        </div>
      );
    }
  });

export default DragFeedback
