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
import {canUseMediaCapture, MediaCapture} from '@instructure/media-capture'
import formatMessage from '../../../../format-message'
import {MediaCaptureStrings} from './MediaCaptureStrings'
import {object, func} from 'prop-types'
import React from 'react'

export default class MediaRecorder extends React.Component {
  saveFile = file => {
    this.props.contentProps.saveMediaRecording(file, this.props.editor, this.props.dismiss)
  }

  render() {
    return (
      <div>
        {canUseMediaCapture() ? (
          <MediaCapture translations={MediaCaptureStrings} onCompleted={this.saveFile} />
        ) : (
          <Alert variant="error" margin="small">
            {formatMessage('Error uploading video/audio recording')}
          </Alert>
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
