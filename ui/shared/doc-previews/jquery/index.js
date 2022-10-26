/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_helpers' /*  /\$\.uniq/, capitalize */
import '@canvas/loading-image'
import {isPreviewable, loadDocPreview} from '@instructure/canvas-rce'

// check to see if a file of a certan mimeType is previewable inline in the browser by either scribd or googleDocs
// ex: $.isPreviewable("application/mspowerpoint")  -> true
$.isPreviewable = (type, service = undefined) => {
  if (service === 'google' && INST?.disableGooglePreviews) return false
  return isPreviewable(type)
}

$.fn.loadDocPreview = function (options) {
  const $this = $(this)
  loadDocPreview($this[0], options)
}
