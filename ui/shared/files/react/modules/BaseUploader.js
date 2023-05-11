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
import axios from '@canvas/axios'
import {completeUpload} from '@canvas/upload-file'

export default class BaseUploader {
  constructor(fileOptions, folder) {
    this.file = fileOptions.file
    this.options = fileOptions
    this.folder = folder
    this.progress = 0
    this._cancelRequest = null
    this._cancelToken = null
    // inFlight is true as long as the upload is taking place.
    // this includes the time it takes for ZipUploader to unzip
    // its file after the upload itself completes
    this.inFlight = false
  }

  onProgress(_percentComplete, _file) {}
  // noop will be set up a level

  createPreFlightParams() {
    return {
      name: this.options.name || this.file.name,
      size: this.file.size,
      content_type: this.file.type,
      on_duplicate: this.options.dup || 'rename',
      parent_folder_id: this.folder.id,
      no_redirect: true,
      category: this.options.category,
    }
  }

  getPreflightUrl() {
    return `/api/v1/folders/${this.folder.id}/files`
  }

  onPreflightComplete = ({data}) => {
    this.uploadData = data
    return this._actualUpload()
  }

  // kickoff / preflight upload process
  upload() {
    this._cancelToken = new axios.CancelToken(canceller => {
      this._cancelRequest = canceller
    })

    this.inFlight = true
    return axios({
      url: this.getPreflightUrl(),
      method: 'POST',
      data: this.createPreFlightParams(),
      responseType: 'json',
      cancelToken: this._cancelToken,
    })
      .then(this.onPreflightComplete)
      .catch(failReason => {
        this.inFlight = false
        if (axios.isCancel(failReason)) {
          this.onUploadCancelled()
          // eslint-disable-next-line no-throw-literal
          throw 'user_aborted_upload'
        } else {
          this.error = failReason
          throw failReason
        }
      })
  }

  // actual upload based on kickoff / preflight
  _actualUpload() {
    return completeUpload(this.uploadData, this.file, {
      ajaxLib: axios,
      onProgress: this.trackProgress,
      ajaxLibOptions: {
        cancelToken: this._cancelToken,
      },
    }).then(this.onUploadPosted)
  }

  // be careful if you ever need to change this implementation there
  // is other code that replaces BaseUploader.prototype.onUploadPosted
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  onUploadPosted(attachment) {}

  onUploadCancelled(_file) {
    this.inFlight = false
  }

  // should be implemented in extensions

  trackProgress = e => {
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

  getFileType() {
    return this.file.type
  }

  getFileName() {
    return this.options.name || this.file.name
  }

  canAbort = () => {
    return !!this._cancelToken
  }

  abort = () => {
    this?._cancelRequest()
    this.onUploadCancelled(this.file)
  }

  reset() {
    this.error = null
    this.progress = 0
  }
}
