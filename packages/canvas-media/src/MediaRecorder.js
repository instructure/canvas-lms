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

import React from 'react'

import {Alert} from '@instructure/ui-alerts'
import {canUseMediaCapture, MediaCapture} from '@instructure/media-capture'
import {func, object, string} from 'prop-types'

import saveMediaRecording from './saveMediaRecording'

export default class MediaRecorder extends React.Component {
  saveFile = file => {
    saveMediaRecording(file, this.props.contextId, this.props.contextType, this.props.dismiss)
  }

  render() {
    return (
      <div>
        {canUseMediaCapture() ? (
          <MediaCapture translations={this.props.MediaCaptureStrings} onCompleted={this.saveFile} />
        ) : (
          <Alert variant="error" margin="small">
            {this.props.errorMessage}
          </Alert>
        )}
      </div>
    )
  }
}

MediaRecorder.propTypes = {
  contextId: string,
  contextType: string,
  dismiss: func,
  errorMessage: string.isRequired,
  MediaCaptureStrings: object // eslint-disable-line react/forbid-prop-types
}
