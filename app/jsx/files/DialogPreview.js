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
import customPropTypes from 'compiled/react_files/modules/customPropTypes'
import Folder from 'compiled/models/Folder'
import filesEnv from 'compiled/react_files/modules/filesEnv'
import FilesystemObjectThumbnail from '../files/FilesystemObjectThumbnail'

  var MAX_THUMBNAILS_TO_SHOW = 5;

  // This is used to show a preview inside of a modal dialog.
  var DialogPreview = React.createClass({
    displayName: 'DialogPreview',

    propTypes: {
      itemsToShow: PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired
    },

    renderPreview () {
      if (this.props.itemsToShow.length === 1) {
        return (
          <FilesystemObjectThumbnail
            model={this.props.itemsToShow[0]}
            className='DialogPreview__thumbnail'
          />
        );
      } else {
        return this.props.itemsToShow.slice(0, MAX_THUMBNAILS_TO_SHOW).map((model, index) => {
          return (
            <i
              key={model.cid}
              className='media-object ef-big-icon FilesystemObjectThumbnail mimeClass-file DialogPreview__thumbnail'
              style={{
                left: (10 * index),
                top: (-140 * index)
              }}
            />
          );
        });
      }
    },

    render () {
      return (
        <div className='DialogPreview__container'>
          {this.renderPreview()}
        </div>
      );
    }
  });

export default DialogPreview
