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
import I18n from 'i18n!course_images'
import _ from 'underscore'
import UploadArea from './UploadArea'
import FlickrSearch from '../../shared/FlickrSearch'
import Spinner from 'instructure-ui/lib/components/Spinner'

  class CourseImagePicker extends React.Component {
    constructor (props) {
      super(props);

      this.state = {
        draggingFile: false
      };

      this.onDrop = this.onDrop.bind(this);
      this.onDragLeave = this.onDragLeave.bind(this);
      this.onDragEnter = this.onDragEnter.bind(this);
      this.shouldAcceptDrop = this.shouldAcceptDrop.bind(this);
    }

    onDrop (e) {
      this.setState({draggingFile: false});
      this.props.handleFileUpload(e, this.props.courseId);
      e.preventDefault();
      e.stopPropagation();
    }

    onDragLeave () {
      this.setState({draggingFile: false});
    }

    onDragEnter (e) {
      if (this.shouldAcceptDrop(e.dataTransfer)) {
        this.setState({draggingFile: true});
        e.preventDefault();
        e.stopPropagation();
      }
    }

    shouldAcceptDrop (dataTransfer) {
      if (dataTransfer) {
        return (_.indexOf(dataTransfer.types, 'Files') >= 0);
      }
    }

    render () {
      return (
        <div className="CourseImagePicker"
          onDrop={this.onDrop}
          onDragLeave={this.onDragLeave}
          onDragOver={this.onDragEnter}
          onDragEnter={this.onDragEnter}>
          { this.props.uploadingImage ?
            <div className="CourseImagePicker__Overlay">
              <Spinner title="Loading"/>
            </div>
            :
            null
          }
          { this.state.draggingFile ?
            <div className="DraggingOverlay CourseImagePicker__Overlay">
              <div className="DraggingOverlay__Content">
                <div className="DraggingOverlay__Icon">
                  <i className="icon-upload" />
                </div>
                <div className="DraggingOverlay__Instructions">
                  {I18n.t('Drop Image')}
                </div>
              </div>
            </div>
            :
            null
          }
          <div className="ic-Action-header CourseImagePicker__Header">
            <h3 className="ic-Action-header__Heading">{I18n.t('Change Image')}</h3>
            <div className="ic-Action-header__Secondary">
              <button
                className="CourseImagePicker__CloseBtn"
                onClick={this.props.handleClose}
                type="button"
              >
                <i className="icon-x" />
                <span className="screenreader-only">
                  {I18n.t('Close')}
                </span>
              </button>
            </div>
          </div>
          <div className="CourseImagePicker__Content">
            <UploadArea
              courseId={this.props.courseId}
              handleFileUpload={this.props.handleFileUpload}/>
            <FlickrSearch selectImage={(flickrUrl) => this.props.handleFlickrUrlUpload(flickrUrl)} />
          </div>
        </div>
      );
    }
  }

export default CourseImagePicker
