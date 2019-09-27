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
import PropTypes from 'prop-types'
import I18n from 'i18n!course_images'
import _ from 'underscore'
import {Spinner} from '@instructure/ui-elements'
import {Tabs} from '@instructure/ui-tabs'
import UploadArea from './UploadArea'
import FlickrSearch from '../../shared/FlickrSearch'
import ImageSearch from '../../shared/ImageSearch'

export default class CourseImagePicker extends React.Component {
  static propTypes = {
    courseId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
    handleFileUpload: PropTypes.func,
    handleImageSearchUrlUpload: PropTypes.func,
    uploadingImage: PropTypes.bool
  }

  static defaultProps = {
    handleFileUpload: () => {},
    handleImageSearchUrlUpload: () => {},
    uploadingImage: false
  }

  state = {
    draggingFile: false,
    selectedIndex: 0
  }

  handleTabChange = (event, {index}) => {
    this.setState({
      selectedIndex: index
    })
  }

  onDrop = e => {
    this.setState({draggingFile: false})
    this.props.handleFileUpload(e, this.props.courseId)
    e.preventDefault()
    e.stopPropagation()
  }

  onDragLeave = () => {
    this.setState({draggingFile: false})
  }

  onDragEnter = e => {
    if (this.shouldAcceptDrop(e.dataTransfer)) {
      this.setState({draggingFile: true})
      e.preventDefault()
      e.stopPropagation()
    }
  }

  shouldAcceptDrop = dataTransfer => {
    if (dataTransfer) {
      return _.indexOf(dataTransfer.types, 'Files') >= 0
    }
  }

  render() {
    const selectedIndex = this.state.selectedIndex
    return (
      <Tabs margin="large auto" maxWidth="60%" onRequestTabChange={this.handleTabChange}>
        <Tabs.Panel renderTitle={I18n.t('Computer')} isSelected={selectedIndex === 0}>
          <div
            className="CourseImagePicker"
            onDrop={this.onDrop}
            onDragLeave={this.onDragLeave}
            onDragOver={this.onDragEnter}
            onDragEnter={this.onDragEnter}
          >
            {this.props.uploadingImage && (
              <div className="CourseImagePicker__Overlay">
                <Spinner renderTitle="Loading" />
              </div>
            )}
            {this.state.draggingFile && (
              <div className="DraggingOverlay CourseImagePicker__Overlay">
                <div className="DraggingOverlay__Content">
                  <div className="DraggingOverlay__Icon">
                    <i className="icon-upload" />
                  </div>
                  <div className="DraggingOverlay__Instructions">{I18n.t('Drop Image')}</div>
                </div>
              </div>
            )}
            <div className="CourseImagePicker__Content">
              <UploadArea
                courseId={this.props.courseId}
                handleFileUpload={this.props.handleFileUpload}
              />
            </div>
          </div>
        </Tabs.Panel>
        {ENV.use_unsplash_image_search ? (
          <Tabs.Panel renderTitle={I18n.t('Unsplash')} isSelected={selectedIndex === 1}>
            <ImageSearch
              selectImage={(imageUrl, confirmationId) =>
                this.props.handleImageSearchUrlUpload(imageUrl, confirmationId)
              }
            />
          </Tabs.Panel>
        ) : (
          <Tabs.Panel renderTitle={I18n.t('Flickr')} isSelected={selectedIndex === 1}>
            <FlickrSearch
              selectImage={imageUrl => this.props.handleImageSearchUrlUpload(imageUrl)}
            />
          </Tabs.Panel>
        )}
      </Tabs>
    )
  }
}
