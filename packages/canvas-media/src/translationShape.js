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

import {shape, string} from 'prop-types'

const translationShape = shape({
  CLEAR_FILE_TEXT: string,
  CLOSE_TEXT: string,
  COMPUTER_PANEL_TITLE: string,
  DRAG_DROP_CLICK_TO_BROWSE: string,
  DRAG_FILE_TEXT: string,
  INVALID_FILE_TEXT: string,
  LOADING_MEDIA: string,
  RECORD_PANEL_TITLE: string,
  SUBMIT_TEXT: string,
  UPLOADING_ERROR: string,
  UPLOAD_MEDIA_LABEL: string
})

export default translationShape
