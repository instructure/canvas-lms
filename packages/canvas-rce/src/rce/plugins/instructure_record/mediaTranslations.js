/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

// IMPORTANT!
// Do not import this file directly, but get it via Bridge.uploadMediaTranslations
// This is because the locale, which is lazy imported, has to be loaded and
// format-message initialized before this file gets evaluated.
import formatMessage from '../../../format-message'

const uploadMediaTranslations = {
  UploadMediaStrings: {
    ADD_CLOSED_CAPTIONS_OR_SUBTITLES: formatMessage('Add CC/Subtitles'),
    CLEAR_FILE_TEXT: formatMessage('Clear selected file'),
    CLOSE_TEXT: formatMessage('Close'),
    CLOSED_CAPTIONS_CHOOSE_FILE: formatMessage('Choose caption file'),
    CLOSED_CAPTIONS_SELECT_LANGUAGE: formatMessage('Select Language'),
    COMPUTER_PANEL_TITLE: formatMessage('Computer'),
    DRAG_DROP_CLICK_TO_BROWSE: formatMessage('Drag and drop, or click to browse your computer'),
    DRAG_FILE_TEXT: formatMessage('Drag a file here'),
    EMBED_PANEL_TITLE: formatMessage('Embed'),
    EMBED_VIDEO_CODE_TEXT: formatMessage('Embed Code'),
    INVALID_FILE_TEXT: formatMessage('Invalid File'),
    LOADING_MEDIA: formatMessage('Loading...'),
    RECORD_PANEL_TITLE: formatMessage('Record'),
    SUBMIT_TEXT: formatMessage('Submit'),
    UPLOADING_ERROR: formatMessage('An error occurred uploading your media.'),
    UPLOAD_MEDIA_LABEL: formatMessage('Upload Media'),
    MEDIA_RECORD_NOT_AVAILABLE: formatMessage(
      'Audio and video recording not supported; please use a different browser.'
    ),
    SUPPORTED_FILE_TYPES: formatMessage('Supported file types: SRT or WebVTT'),
    NO_FILE_CHOSEN: formatMessage('No file chosen'),
    REMOVE_FILE: 'Remove {lang} closed captions',
    ADD_NEW_CAPTION_OR_SUBTITLE: formatMessage('Add another'),
    ADDED_CAPTION: 'Captions for {lang} added',
    DELETED_CAPTION: 'Deleted captions for {lang}',
    PROGRESS_LABEL: formatMessage('Uploading'),
  },

  SelectStrings: {
    USE_ARROWS: 'Use arrow keys to navigate options.',
    LIST_COLLAPSED: 'List collapsed.',
    LIST_EXPANDED: 'List expanded.',
    OPTION_SELECTED: '{option} selected.',
  },

  // Structure copied from @instructure/media-capture translations file
  MediaCaptureStrings: {
    ARIA_TIMEBAR_LABEL: formatMessage('Timebar'),
    ARIA_VIDEO_LABEL: formatMessage('Video Player'),
    ARIA_VOLUME: formatMessage('Current Volume Level'),
    ARIA_RECORDING: formatMessage('Recording'),
    DEFAULT_ERROR: formatMessage('Something went wrong accessing your webcam.'),
    DEVICE_AUDIO: formatMessage('Mic'),
    DEVICE_VIDEO: formatMessage('Webcam'),
    FILE_PLACEHOLDER: formatMessage('Untitled'),
    FINISH: formatMessage('Finish'),
    WEBCAM_VIDEO_SELECTION_LABEL: formatMessage('Select video source'),
    WEBCAM_AUDIO_SELECTION_LABEL: formatMessage('Select audio source'),
    NO_WEBCAM: formatMessage('No Video'),
    // Modified string to match from ui/shared/media-recorder/react/components/MediaRecorder.js
    NOT_ALLOWED_ERROR: formatMessage('Please allow Canvas to access your microphone and webcam.'),
    NOT_READABLE_ERROR: formatMessage('Your webcam may already be in use.'),
    PLAYBACK_PAUSE: formatMessage('Pause'),
    PLAYBACK_PLAY: formatMessage('Play'),
    PREVIEW: formatMessage('PREVIEW'),
    SAVE_MEDIA: formatMessage('Save Media'),
    // Modified string to match from ui/shared/media-recorder/react/components/MediaRecorder.js
    SR_FILE_INPUT: formatMessage('File name'),
    START: formatMessage('Start Recording'),
    START_OVER: formatMessage('Start Over'),
    SCREEN_DEFAULT_ERROR: formatMessage('Something went wrong while sharing your screen.'),
    MIC_BLOCKED: formatMessage('Your microphone is blocked in the browser settings.'),
    WEBCAM_BLOCKED: formatMessage('Your webcam is blocked in the browser settings.'),
    MIC_AND_WEBCAM_BLOCKED: formatMessage(
      'Your webcam and microphone are blocked in the browser settings.'
    ),
    NO_MIC_EXIST: formatMessage(
      'We couldn’t detect a working microphone connected to your device.'
    ),
    NO_WEBCAM_EXIST: formatMessage('We couldn’t detect a working webcam connected to your device.'),
    NO_MIC_AND_WEBCAM_EXIST: formatMessage(
      'We couldn’t detect a working webcam or microphone connected to your device.'
    ),
    WEBCAM_DISABLED: formatMessage('Webcam Disabled'),
    MICROPHONE_DISABLED: formatMessage('Microphone Disabled'),
    SYSTEM_AUDIO_ALLOWED: formatMessage('System Audio Allowed'),
    SYSTEM_AUDIO_DISABLED: formatMessage('System Audio Disabled'),
  },
}
export default uploadMediaTranslations
