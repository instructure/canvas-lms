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

import {Assignment} from '../../graphqlData/Assignment'
import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import closedCaptionLanguages from '../../../../shared/closedCaptionLanguages'
import elideString from '../../../../shared/helpers/elideString'
import I18n from 'i18n!assignments_2_media_attempt'
import {IconTrashLine, IconAttachMediaLine} from '@instructure/ui-icons'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import UploadMedia from '@instructure/canvas-media'
import {UploadMediaStrings, MediaCaptureStrings} from '../../../../shared/UploadMediaTranslations'
import {View} from '@instructure/ui-layout'

const languages = Object.keys(closedCaptionLanguages).map(key => {
  return {id: key, label: closedCaptionLanguages[key]}
})

export const VIDEO_SIZE_OPTIONS = {height: '400px', width: '768px'}

export default class MediaAttempt extends React.Component {
  static propTypes = {
    assignment: Assignment.shape
  }

  state = {
    mediaModalOpen: false,
    mediaObject: null
  }

  onDismiss = (err, mediaObject) => {
    this.setState({mediaModalOpen: false, mediaObject})
  }

  handleRemoveFile = () => {
    this.setState({mediaObject: null})
  }

  renderMediaPlayer = () => {
    const mediaObject = this.state.mediaObject.media_object
    return (
      <div style={{display: 'flex', alignItems: 'center', flexDirection: 'column'}}>
        <div style={{width: VIDEO_SIZE_OPTIONS.width, height: VIDEO_SIZE_OPTIONS.height}}>
          <iframe
            style={{width: '100%', height: '100%'}}
            title={I18n.t('Media Submission')}
            src={this.state.mediaObject.embedded_iframe_url}
          />
        </div>
        <div>
          <span aria-hidden title={mediaObject.title}>
            {elideString(mediaObject.title)}
          </span>
          <ScreenReaderContent>{mediaObject.title}</ScreenReaderContent>
          <Button
            icon={IconTrashLine}
            id={mediaObject.id}
            margin="0 0 0 x-small"
            onClick={this.handleRemoveFile}
            size="small"
          >
            <ScreenReaderContent>
              {I18n.t('Remove %{filename}', {filename: mediaObject.title})}
            </ScreenReaderContent>
          </Button>
        </div>
      </div>
    )
  }

  render() {
    if (this.state.mediaObject) {
      return this.renderMediaPlayer()
    }

    return (
      <View as="div" borderWidth="small">
        <UploadMedia
          onDismiss={this.onDismiss}
          contextId={this.props.assignment.env.courseId}
          contextType="course"
          open={this.state.mediaModalOpen}
          tabs={{embed: false, record: true, upload: true}}
          uploadMediaTranslations={{UploadMediaStrings, MediaCaptureStrings}}
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          languages={languages}
        />
        <Billboard
          heading={I18n.t('Add Media')}
          hero={<IconAttachMediaLine color="brand" />}
          message={
            <Button
              size="small"
              data-testid="media-modal-launch-button"
              variant="primary"
              onClick={() => this.setState({mediaModalOpen: true})}
            >
              {I18n.t('Record/Upload')}
            </Button>
          }
        />
      </View>
    )
  }
}
