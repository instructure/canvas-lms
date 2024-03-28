/* eslint-disable eslint-comments/no-unlimited-disable */
/* eslint-disable */

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

import signatureBuilder from './signature_builder'
import urlParams from './url_params'
import k5Options from './k5_options'

function KalturaRequestBuilder() {
  this.settings, this.file
  this.xhr
}

KalturaRequestBuilder.id = 1

KalturaRequestBuilder.prototype.createRequest = function () {
  const xhr = new XMLHttpRequest()
  xhr.open('POST', this.createUrl())
  xhr.responseType = 'text'
  return xhr
}

KalturaRequestBuilder.prototype.createFormData = function () {
  const formData = new FormData()
  formData.append('Filename', this.file.name)
  formData.append('Filedata', this.file)
  formData.append('Upload', 'Submit Query')
  return formData
}

KalturaRequestBuilder.prototype.createFileId = function () {
  KalturaRequestBuilder.id += 1
  return Date.now().toString() + KalturaRequestBuilder.id.toString()
}

// flash uploader sends these as GET query params
// and file data as POST
KalturaRequestBuilder.prototype.createUrl = function () {
  const config = this.settings.getSession()
  config.filename = this.createFileId()
  config.kalsig = this.createSignature()
  return k5Options.uploadUrl + urlParams(config)
}

KalturaRequestBuilder.prototype.createSignature = function () {
  return signatureBuilder(this.settings.getSession())
}

KalturaRequestBuilder.prototype.buildRequest = function (settings, file) {
  this.settings = settings
  this.file = file
  return this.createRequest()
}

KalturaRequestBuilder.prototype.getFile = function () {
  return this.file
}

KalturaRequestBuilder.prototype.getSettings = function () {
  return this.settings
}

export default KalturaRequestBuilder
