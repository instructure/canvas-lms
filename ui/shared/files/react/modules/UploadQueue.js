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

import {pull} from 'lodash'
import FileUploader from './FileUploader'
import ZipUploader from './ZipUploader'

class UploadQueue {
  length() {
    return this._queue.length
  }

  pendingUploads() {
    return this._queue.length + (this.currentUploader ? 1 : 0)
  }

  flush() {
    this._queue = []
    this.currentUploader = null
    this.onChange()
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

  listeners = []

  addChangeListener(callback) {
    this.listeners.push(callback)
  }

  removeChangeListener(callback) {
    this.listeners = this.listeners.filter(l => l !== callback)
  }

  onChange() {
    this.listeners.forEach(l => l(this))
  }

  createUploader(fileOptions, folder, contextId, contextType) {
    const uploader = fileOptions.expandZip
      ? new ZipUploader(fileOptions, folder, contextId, contextType)
      : new FileUploader(fileOptions, folder)
    uploader.onProgress = () => {
      this.onChange()
    }
    uploader.cancel = () => {
      uploader.abort()
      pull(this._queue, uploader)
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
    const firstNonErroredUpload = this._queue.find(upload => !upload.error)
    pull(this._queue, firstNonErroredUpload)
    return firstNonErroredUpload
  }

  removeUploaderFromQueue(uploader) {
    if (uploader.error || uploader.inFlight) return
    const index = this._queue.findIndex(u => u === uploader)
    if (index >= 0) {
      this._queue.splice(index, 1)
    }
  }

  pageChangeWarning(event) {
    event.preventDefault()
    event.returnValue = ''
  }

  attemptNextUpload() {
    if (this._uploading || this._queue.length === 0) return
    const uploader = this.dequeue()
    this.attemptThisUpload(uploader)
  }

  attemptThisUpload(uploader) {
    if (!uploader) {
      return
    }

    uploader.reset()

    if (this._uploading) {
      return
    }
    // when retrying, the uploader is still queued
    this.removeUploaderFromQueue(uploader)
    this.currentUploader = uploader
    this.onChange()
    this._uploading = true
    window.addEventListener('beforeunload', this.pageChangeWarning)

    return uploader
      .upload()
      .catch(failReason => {
        // put it back in the queue unless the user aborted it
        if (failReason !== 'user_aborted_upload') {
          return this._queue.unshift(uploader)
        }
      })
      .finally(() => {
        this._uploading = false
        if (!this.currentUploader?.inFlight) {
          this.currentUploader = null
        }
        window.removeEventListener('beforeunload', this.pageChangeWarning)
        this.onChange()
        this.attemptNextUpload()
      })
  }
}
UploadQueue.prototype._uploading = false
UploadQueue.prototype._queue = []

export default new UploadQueue()
