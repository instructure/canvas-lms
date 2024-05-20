/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import BBFile from '../../backbone/models/File'
import BaseUploader from './BaseUploader'

export default class FileUploader extends BaseUploader {
  constructor(fileOptions, folder) {
    super(fileOptions, folder)
    this.onUploadPosted = this.onUploadPosted.bind(this)
  }

  onUploadPosted(fileJson) {
    this.inFlight = false
    if (this.options.replacingFileId) {
      fileJson.replacingFileId = this.options.replacingFileId
    }
    this.addFileToCollection(fileJson)
    super.onUploadPosted(fileJson)
  }

  addFileToCollection = attrs => {
    if (this.folder?.files?.add) {
      // exists on the Files page, but nowhere else
      const uploadedFile = new BBFile(attrs, 'no/url/needed/') // we've already done the upload, no preflight needed

      this.folder.files.add(uploadedFile, {merge: true})
      // remove old version if it was just overwritten (unless it was overwritten in place and the id is unchanged)
      if (this.options.dup === 'overwrite' && this.options.replacingFileId !== attrs.id) {
        const previous = this.folder.files.get(this.options.replacingFileId)
        if (previous) {
          this.folder.files.remove(previous)
        }
      }
    }
  }
}
