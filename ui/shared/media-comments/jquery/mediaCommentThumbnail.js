//
// Copyright (C) 2011 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
// This import is super-specific on purpose. The RCE uses barrel imports/exports, which rspack
// can't/won't optimize due to side-effects. By being this specific, we keep the bundle size down.
import mediaCommentThumbnail from '@instructure/canvas-rce/es/enhance-user-content/media_comment_thumbnail'

// public API
export default ($.fn.mediaCommentThumbnail = function (size = 'normal', keepOriginalText) {
  return this.each(function () {
    return mediaCommentThumbnail(this, size, keepOriginalText, INST.kalturaSettings, $(this).data())
  })
})
