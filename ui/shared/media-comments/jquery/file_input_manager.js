//
// Copyright (C) 2014 - present Instructure, Inc.
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

/*
 * builds and interacts with hidden input file for kaltura uploads
 */
export default class FileInputManager {
  resetFileInput = (callback, id, parentId) => {
    if (!id) id = 'file_upload'
    if (!parentId) parentId = '#media_upload_settings'
    if (this.$fileInput) {
      this.$fileInput.off('change', callback)
      this.$fileInput.remove()
    }
    const fileInputHtml = `<input id='${id}' type='file' style='display: none;'>`
    $(parentId).append(fileInputHtml)
    this.$fileInput = $(`#${id}`)
    return this.$fileInput.on('change', callback)
  }

  setUpInputTrigger(el, mediaType) {
    $(el).on('click', _e => {
      this.allowedMedia = mediaType
      return this.$fileInput.click()
    })
  }

  getSelectedFile() {
    return this.$fileInput.get()[0].files[0]
  }
}
