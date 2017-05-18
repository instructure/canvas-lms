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
import Folder from 'compiled/models/Folder'
import mimeClass from 'compiled/util/mimeClass'
import FilesystemObjectThumbnail from 'compiled/react_files/components/FilesystemObjectThumbnail'

  FilesystemObjectThumbnail.render = function () {
    var additionalClassName = this.props.className ? this.props.className : '';

    if (this.state.thumbnail_url) {
      return (
        <span
          className={`media-object ef-thumbnail FilesystemObjectThumbnail ${additionalClassName}`}
          style = { {backgroundImage: `url('${this.state.thumbnail_url}')`} }
        ></span>
      );
    } else {
      var thumbnailClassName = (this.props.model instanceof Folder) ?
        (this.props.model.get('for_submissions') ? 'folder-locked' : 'folder') :
        mimeClass(this.props.model.get('content-type'));
      return (
        <i
          className={`media-object ef-big-icon FilesystemObjectThumbnail mimeClass-${thumbnailClassName} ${additionalClassName}`}
        ></i>
      );
    }
  };

export default React.createClass(FilesystemObjectThumbnail)
