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

import formatMessage from '../../../../format-message'

const MediaCaptureStrings = {
  ARIA_VIDEO_LABEL: formatMessage('Video Player'),
  ARIA_VOLUME: formatMessage('Current Volume Level'),
  ARIA_RECORDING: formatMessage('Recording'),
  DEFAULT_ERROR: formatMessage('Something went wrong accessing your mic or webcam.'),
  DEVICE_AUDIO: formatMessage('Mic'),
  DEVICE_VIDEO: formatMessage('Webcam'),
  FILE_PLACEHOLDER: formatMessage('Untitled'),
  FINISH: formatMessage('Finish'),
  NO_WEBCAM: formatMessage('No Video'),
  NOT_ALLOWED_ERROR: formatMessage('Please allow Canvas to access your microphone and webcam.'),
  NOT_READABLE_ERROR: formatMessage('Your webcam may already be in use.'),
  PLAYBACK_PAUSE: formatMessage('Pause'),
  PLAYBACK_PLAY: formatMessage('Play'),
  PREVIEW: formatMessage('PREVIEW'),
  SAVE: formatMessage('Save'),
  SR_FILE_INPUT: formatMessage('File name'),
  START: formatMessage('Start Recording'),
  START_OVER: formatMessage('Start Over')
}

export {MediaCaptureStrings}
