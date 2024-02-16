/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import mBus from './message_bus'
import UploadResult from './upload_result'
import KalturaRequestBuilder from './kaltura_request_builder'

function Uploader() {
  this.xhr = new XMLHttpRequest()
  this.uploadResult = new UploadResult()
}

Uploader.prototype.isAvailable = function () {
  return !!this.xhr.upload
}

Uploader.prototype.send = function (session, file) {
  const kRequest = new KalturaRequestBuilder()
  this.xhr = kRequest.buildRequest(session, file)
  this.addEventListeners()
  this.xhr.send(kRequest.createFormData())
}

Uploader.prototype.addEventListeners = function () {
  this.xhr.upload.addEventListener('progress', this.eventProxy.bind(this.xhr))
  this.xhr.upload.addEventListener('load', this.eventProxy.bind(this.xhr))
  this.xhr.upload.addEventListener('error', this.eventProxy.bind(this.xhr))
  this.xhr.upload.addEventListener('abort', this.eventProxy.bind(this.xhr))
  this.xhr.onload = this.onload.bind(this)
}

Uploader.prototype.onload = function (event) {
  this.uploadResult.parseXML(this.xhr.response)
  const resultStatus = this.uploadResult.isError ? 'error' : 'success'
  mBus.dispatchEvent('Uploader.' + resultStatus, this.uploadResult)
}

Uploader.prototype.eventProxy = function (event) {
  const name = 'Uploader.' + event.type
  mBus.dispatchEvent(name, event, this)
}

export default Uploader
