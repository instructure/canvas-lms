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
import formatMessage from '../../../format-message'

const uploadMediaTranslations = {
  UploadMediaStrings: {
    ADD_CLOSED_CAPTIONS_OR_SUBTITLES: formatMessage('Add CC/Subtitles'),
    CLEAR_FILE_TEXT: formatMessage('Clear selected file'),
    CLOSE_TEXT: formatMessage('Close'),
    CLOSED_CAPTIONS_CHOOSE_FILE: formatMessage('Choose caption file'),
    CLOSED_CAPTIONS_SELECT_LANGUAGE: formatMessage('Select Language'),
    COMPUTER_PANEL_TITLE: formatMessage('Computer'),
    DRAG_DROP_CLICK_TO_BROWSE: formatMessage('Drop and drop, or click to browse your computer'),
    DRAG_FILE_TEXT: formatMessage('Drag a file here'),
    EMBED_PANEL_TITLE: formatMessage('Embed'),
    EMBED_VIDEO_CODE_TEXT: formatMessage('Embed Code'),
    INVALID_FILE_TEXT: formatMessage('Invalid File'),
    LOADING_MEDIA: formatMessage('Loading...'),
    RECORD_PANEL_TITLE: formatMessage('Record'),
    SUBMIT_TEXT: formatMessage('Submit'),
    UPLOADING_ERROR: formatMessage('Upload Error'),
    UPLOAD_MEDIA_LABEL: formatMessage('Upload Media'),
    MEDIA_RECORD_NOT_AVAILABLE: formatMessage('Audio and Video recording is not available.'),
    SUPPORTED_FILE_TYPES: formatMessage('Supported file types: SRT or WebVTT'),
    NO_FILE_CHOSEN: formatMessage('No file chosen'),
    REMOVE_FILE: 'Remove {lang} closed captions',
    ADD_NEW_CAPTION_OR_SUBTITLE: formatMessage('Add another'),
    ADDED_CAPTION: 'Captions for {lang} added',
    DELETED_CAPTION: 'Deleted captions for {lang}'
  },

  SelectStrings: {
    USE_ARROWS: 'Use arrow keys to navigate options.',
    LIST_COLLAPSED: 'List collapsed.',
    LIST_EXPANDED: 'List expanded.',
    OPTION_SELECTED: '{option} selected.'
  }
}
export default uploadMediaTranslations
