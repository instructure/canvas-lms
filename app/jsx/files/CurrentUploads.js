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
import createReactClass from 'create-react-class';
import classnames from 'classnames'
import CurrentUploads from 'compiled/react_files/components/CurrentUploads'
import UploadProgress from '../files/UploadProgress'

    CurrentUploads.renderUploadProgress = function () {
      if (this.state.currentUploads.length) {
        var progessComponents = this.state.currentUploads.map((uploader) => {
          return <UploadProgress uploader={uploader} key={uploader.getFileName()} />
        });
        return (
          <div className='current_uploads__uploaders'>
            {progessComponents}
          </div>
        );
      } else {
        return null;
      }
    };

    CurrentUploads.render = function () {
      var classes = classnames({
        'current_uploads': this.state.currentUploads.length
      });

      return (
        <div className={classes}>
          {this.renderUploadProgress()}
        </div>
      );
    };

export default createReactClass(CurrentUploads);
