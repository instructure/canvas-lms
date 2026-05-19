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

import {canUseMediaCapture, ScreenCapture} from '@instructure/media-capture'

import {Alert} from '@instructure/ui-alerts'
import {func, object, string} from 'prop-types'
import React from 'react'

export default function MediaRecorder(props) {
  return (
    <div>
      {canUseMediaCapture() ? (
        // In @instructure/media-capture v11, MediaCapture was replaced by ScreenCapture (ARC-9172).
        // noScreenSharing preserves the original webcam-only behavior.
        <ScreenCapture
          translations={props.MediaCaptureStrings}
          onCompleted={props.onSave}
          noScreenSharing={true}
        />
      ) : (
        <Alert variant="info" margin="small">
          {props.errorMessage}
        </Alert>
      )}
    </div>
  )
}

MediaRecorder.propTypes = {
  onSave: func.isRequired,
  errorMessage: string.isRequired,
  MediaCaptureStrings: object,
}
