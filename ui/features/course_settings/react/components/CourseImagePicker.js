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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {Tabs} from '@instructure/ui-tabs'
import {FileDrop} from '@instructure/ui-file-drop'
import {Billboard} from '@instructure/ui-billboard'
import {Text} from '@instructure/ui-text'
import {getIconByType} from '@canvas/mime/react/mimeClassIconHelper'

const I18n = useI18nScope('course_images')

const dropIcon = getIconByType('image')

export default class CourseImagePicker extends React.Component {
  static propTypes = {
    courseId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
    handleFileUpload: PropTypes.func,
    uploadingImage: PropTypes.bool,
  }

  static defaultProps = {
    handleFileUpload: () => {},
    uploadingImage: false,
  }

  state = {
    selectedIndex: 0,
    fileDropMessages: null,
  }

  handleTabChange = (event, {index}) => {
    this.setState({
      selectedIndex: index,
    })
  }

  handleDropAccepted = files => {
    this.setState({fileDropMessages: null})
    this.props.handleFileUpload(
      {
        dataTransfer: {files},
        preventDefault: () => {},
        stopPropagagtion: () => {},
      },
      this.props.courseId
    )
  }

  handleDropRejected = () => {
    this.setState({
      fileDropMessages: [{text: I18n.t('File must be an image'), type: 'error'}],
    })
  }

  render() {
    const selectedIndex = this.state.selectedIndex
    return (
      <Tabs margin="large auto" maxWidth="60%" onRequestTabChange={this.handleTabChange}>
        <Tabs.Panel renderTitle={I18n.t('Computer')} isSelected={selectedIndex === 0}>
          {this.props.uploadingImage ? (
            <div className="CourseImagePicker__Overlay">
              <Spinner renderTitle="Loading" />
            </div>
          ) : (
            <FileDrop
              accept="image/*"
              renderLabel={
                <Billboard
                  heading={I18n.t('Upload Image')}
                  hero={dropIcon}
                  message={
                    <Text size="small">
                      {I18n.t('Drag and drop, or click to browse your computer')}
                    </Text>
                  }
                />
              }
              messages={this.state.fileDropMessages}
              onDropAccepted={this.handleDropAccepted}
              onDropRejected={this.handleDropRejected}
            />
          )}
        </Tabs.Panel>
      </Tabs>
    )
  }
}
