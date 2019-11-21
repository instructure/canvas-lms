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

import I18n from 'i18n!media_capture_strings'

const MediaCaptureStrings = {
  ARIA_VIDEO_LABEL: I18n.t('Video Player'),
  ARIA_VOLUME: I18n.t('Current Volume Level'),
  ARIA_RECORDING: I18n.t('Recording'),
  DEFAULT_ERROR: I18n.t('Something went wrong accessing your mic or webcam.'),
  DEVICE_AUDIO: I18n.t('Mic'),
  DEVICE_VIDEO: I18n.t('Webcam'),
  FILE_PLACEHOLDER: I18n.t('Untitled'),
  FINISH: I18n.t('Finish'),
  NO_WEBCAM: I18n.t('No Video'),
  NOT_ALLOWED_ERROR: I18n.t('Please allow Canvas to access your microphone and webcam.'),
  NOT_READABLE_ERROR: I18n.t('Your webcam may already be in use.'),
  PLAYBACK_PAUSE: I18n.t('Pause'),
  PLAYBACK_PLAY: I18n.t('Play'),
  PREVIEW: I18n.t('PREVIEW'),
  SAVE: I18n.t('Save'),
  SR_FILE_INPUT: I18n.t('File name'),
  START: I18n.t('Start Recording'),
  START_OVER: I18n.t('Start Over')
}

const UploadMediaStrings = {
  LOADING_MEDIA: I18n.t('Loading Media'),
  ADD_CLOSED_CAPTIONS_OR_SUBTITLES: I18n.t('Add CC/Subtitle'),
  COMPUTER_PANEL_TITLE: I18n.t('Computer'),
  DRAG_FILE_TEXT: I18n.t('Drag a File Here'),
  RECORD_PANEL_TITLE: I18n.t('Record'),
  EMBED_PANEL_TITLE: I18n.t('Embed'),
  SUBMIT_TEXT: I18n.t('Submit'),
  CLOSE_TEXT: I18n.t('Close'),
  UPLOAD_MEDIA_LABEL: I18n.t('Upload Media'),
  CLEAR_FILE_TEXT: I18n.t('Clear selected file'),
  INVALID_FILE_TEXT: I18n.t('Invalid file type'),
  DRAG_DROP_CLICK_TO_BROWSE: I18n.t('Drag and drop, or click to browse your computer'),
  EMBED_VIDEO_CODE_TEXT: I18n.t('Embed Video Code'),
  UPLOADING_ERROR: I18n.t('Error uploading video/audio recording'),
  CLOSED_CAPTIONS_PANEL_TITLE: I18n.t('CC/Subtitles'),
  CLOSED_CAPTIONS_LANGUAGE_HEADER: I18n.t('Language'),
  CLOSED_CAPTIONS_FILE_NAME_HEADER: I18n.t('File Name'),
  CLOSED_CAPTIONS_ACTIONS_HEADER: I18n.t('Actions'),
  CLOSED_CAPTIONS_ADD_SUBTITLE: I18n.t('Subtitle'),
  CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER: I18n.t('Add Subtitle'),
  CLOSED_CAPTIONS_CHOOSE_FILE: I18n.t('Choose File'),
  CLOSED_CAPTIONS_SELECT_LANGUAGE: I18n.t('Select Language'),
  MEDIA_RECORD_NOT_AVAILABLE: I18n.t('Media record not available')
}

export {MediaCaptureStrings, UploadMediaStrings}
