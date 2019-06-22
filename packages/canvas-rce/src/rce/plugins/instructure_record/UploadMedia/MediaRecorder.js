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

import {Alert} from '@instructure/ui-alerts'
import formatMessage from '../../../../format-message'
import {Mask} from '@instructure/ui-overlays'
import {MediaCapture, canUseMediaCapture} from '@instructure/media-capture'
import {MediaCaptureStrings} from './MediaCaptureStrings'
import {object, func} from 'prop-types'
import React from 'react'
import {Spinner} from '@instructure/ui-elements'

const ALERT_TIMEOUT = 5000

export default class MediaRecorder extends React.Component {
  saveFile = (file) => {
    this.props.contentProps.saveMediaRecording(file, this.props.editor, this.props.dismiss)
  }

  render() {
    return (
      <div>
        {this.props.contentProps.upload.uploadingMediaStatus.loading && <Mask>
          <Spinner renderTitle={formatMessage('Loading')} size="large" margin="0 0 0 medium" />
        </Mask>}
        {this.props.contentProps.upload.uploadingMediaStatus.error && (
          <Alert
            variant="error"
            margin="small"
            timeout={ALERT_TIMEOUT}
            liveRegion={() => document.getElementById('flash_screenreader_holder')}
          >
            {formatMessage('Error uploading video/audio recording')}
          </Alert>
        )}
        {this.props.contentProps.upload.uploadingMediaStatus.uploaded && (
          <Alert
            screenReaderOnly
            liveRegion={() => document.getElementById('flash_screenreader_holder')}
            timeout={ALERT_TIMEOUT}
          >
            {formatMessage('Video/audio recording uploaded')}
          </Alert>
        )}
        {canUseMediaCapture() && (
          <MediaCapture
            translations={MediaCaptureStrings}
            onCompleted={this.saveFile}
          />
        )}
      </div>
    )
  }
}

MediaRecorder.propTypes = {
  contentProps: object.isRequired,
  dismiss: func.isRequired,
  editor: object.isRequired
}
