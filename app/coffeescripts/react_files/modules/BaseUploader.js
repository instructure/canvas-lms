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

// Base uploader with common api between File and Zip uploads
// (where zip is expanded)
import $ from 'jquery'
import {completeUpload} from 'jsx/shared/upload_file'
import 'jquery.ajaxJSON'

export default class BaseUploader {
  constructor(fileOptions, folder) {
    this.onPreflightComplete = this.onPreflightComplete.bind(this)
    this.onUploadPosted = this.onUploadPosted.bind(this)
    this.trackProgress = this.trackProgress.bind(this)

    this.file = fileOptions.file
    this.options = fileOptions
    this.folder = folder
    this.progress = 0
  }

  onProgress(percentComplete, file) {}
  // noop will be set up a level

  createPreFlightParams() {
    let params
    return (params = {
      name: this.options.name || this.file.name,
      size: this.file.size,
      content_type: this.file.type,
      on_duplicate: this.options.dup || 'rename',
      parent_folder_id: this.folder.id,
      no_redirect: true
    })
  }

  getPreflightUrl() {
    return `/api/v1/folders/${this.folder.id}/files`
  }

  onPreflightComplete(data) {
    this.uploadData = data
    return this._actualUpload()
  }

  // kickoff / preflight upload process
  upload() {
    this.deferred = $.Deferred()
    this.deferred.fail(failReason => {
      this.error = failReason
      if (this.error && this.error.message) $.screenReaderFlashError(this.error.message)
    })

    $.ajaxJSON(
      this.getPreflightUrl(),
      'POST',
      this.createPreFlightParams(),
      this.onPreflightComplete,
      this.deferred.reject
    )
    return this.deferred.promise()
  }

  // actual upload based on kickoff / preflight
  _actualUpload() {
    return completeUpload(this.uploadData, this.file, {onProgress: this.trackProgress})
      .then(this.onUploadPosted)
      .catch(this.deferred.reject)
  }

  onUploadPosted(event) {}
  // should be implemented in extensions

  trackProgress(e) {
    this.progress = e.loaded / e.total
    return this.onProgress(this.progress, this.file)
  }

  getProgress() {
    return this.progress
  }

  roundProgress() {
    const value = this.getProgress() || 0
    return Math.min(Math.round(value * 100), 100)
  }

  getFileName() {
    return this.options.name || this.file.name
  }

  abort() {
    this._xhr.abort()
    return this.deferred.reject('user_aborted_upload')
  }
}
