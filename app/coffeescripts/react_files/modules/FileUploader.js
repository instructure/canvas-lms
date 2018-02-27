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

import BBFile from '../../models/File'
import BaseUploader from './BaseUploader'
import 'jquery.ajaxJSON'

export default class FileUploader extends BaseUploader {
  constructor(...args) {
    super(...args)
    this.onUploadPosted = this.onUploadPosted.bind(this)
    this.addFileToCollection = this.addFileToCollection.bind(this)
  }

  onUploadPosted(fileJson) {
    const file = this.addFileToCollection(fileJson)
    return this.deferred.resolve(file)
  }

  addFileToCollection(attrs) {
    const uploadedFile = new BBFile(attrs, 'no/url/needed/') // we've already done the upload, no preflight needed

    this.folder.files.add(uploadedFile)
    // remove old version if it was just overwritten
    if (this.options.dup === 'overwrite') {
      const name = this.options.name || this.file.name
      const previous = this.folder.files.findWhere({display_name: name})
      if (previous) {
        this.folder.files.remove(previous)
      }
    }
    return uploadedFile
  }
}
