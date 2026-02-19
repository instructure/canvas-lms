/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import CanvasStudioPlayer from '@canvas/canvas-studio-player'
import type {MediaObject} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

interface MediaRecordingSubmissionDisplayProps {
  mediaObject: MediaObject
}

export function MediaRecordingSubmissionDisplay({
  mediaObject,
}: MediaRecordingSubmissionDisplayProps) {
  return (
    <Flex
      direction="column"
      alignItems="center"
      height="100%"
      data-testid="media-recording-submission-display"
    >
      <Flex.Item data-testid="media-recording" width="100%" shouldGrow>
        <CanvasStudioPlayer
          media_id={mediaObject._id}
          explicitSize={{width: '100%', height: '100%'}}
        />
      </Flex.Item>
      {mediaObject.title && (
        <Flex.Item overflowY="visible" margin="medium 0">
          <span aria-hidden={true} title={mediaObject.title}>
            {mediaObject.title}
          </span>
          <ScreenReaderContent>{mediaObject.title}</ScreenReaderContent>
        </Flex.Item>
      )}
    </Flex>
  )
}

export default MediaRecordingSubmissionDisplay
