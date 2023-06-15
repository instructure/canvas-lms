/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery'
import '@canvas/media-comments'
import ready from '@instructure/ready'

ready(() => {
  const $preview = $('#media_preview')
  const data = $preview.data()
  $preview.mediaComment(
    'show_inline',
    data.media_entry_id || 'maybe',
    data.type,
    data.download_url,
    data.attachment_id,
    data.bp_locked_attachment
  )
  if (ENV.NEW_FILES_PREVIEW) {
    $('#media_preview').css({
      margin: '0',
      padding: '0',
      position: 'absolute',
      top: '50%',
      left: '50%',
      '-webkit-transform': 'translate(-50%, -50%)',
      transform: 'translate(-50%, -50%)',
    })
  }
})
