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

import _ from 'underscore'
import FileUploader from './FileUploader'
import ZipUploader from './ZipUploader'

class UploadQueue {
  length() {
    return this._queue.length
  }

  flush() {
    return (this._queue = [])
  }

  getAllUploaders() {
    let all = this._queue.slice()
    if (this.currentUploader) {
      all = all.concat(this.currentUploader)
    }
    return all.reverse()
  }

  getCurrentUploader() {
    return this.currentUploader
  }

  onChange() {}
  // noop, set by components who care about it

  createUploader(fileOptions, folder, contextId, contextType) {
    const uploader = fileOptions.expandZip
      ? new ZipUploader(fileOptions, folder, contextId, contextType)
      : new FileUploader(fileOptions, folder)
    uploader.cancel = () => {
      if (uploader._xhr != null) {
        uploader._xhr.abort()
      }
      this._queue = _.without(this._queue, uploader)
      if (this.currentUploader === uploader) this.currentUploader = null
      return this.onChange()
    }

    return uploader
  }

  enqueue(fileOptions, folder, contextId, contextType) {
    const uploader = this.createUploader(fileOptions, folder, contextId, contextType)
    this._queue.push(uploader)
    return this.attemptNextUpload()
  }

  dequeue() {
    const firstNonErroredUpload = _.find(this._queue, upload => !upload.error)
    this._queue = _.without(this._queue, firstNonErroredUpload)
    return firstNonErroredUpload
  }

  pageChangeWarning() {
    return 'You currently have uploads in progress. If you leave this page, the uploads will stop.'
  }

  attemptNextUpload() {
    let uploader
    this.onChange()
    if (this._uploading || this._queue.length === 0) return
    this.currentUploader = uploader = this.dequeue()
    if (uploader) {
      this.onChange()
      this._uploading = true
      $(window).on('beforeunload', this.pageChangeWarning)

      const promise = uploader.upload()
      promise.fail(failReason => {
        // put it back in the queue unless the user aborted it
        if (failReason !== 'user_aborted_upload') {
          return this._queue.unshift(uploader)
        }
      })

      return promise.always(() => {
        this._uploading = false
        this.currentUploader = null
        $(window).off('beforeunload', this.pageChangeWarning)
        this.onChange()
        return this.attemptNextUpload()
      })
    }
  }
}
UploadQueue.prototype._uploading = false
UploadQueue.prototype._queue = []

export default new UploadQueue()
