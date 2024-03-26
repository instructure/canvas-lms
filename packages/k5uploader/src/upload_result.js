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

function UploadResult() {
  this.xml = undefined
  this.isError = true
  this.token = undefined
  this.filename = ''
  this.fileId = -1
}

UploadResult.prototype.parseXML = function (xml) {
  const parser = new DOMParser()
  this.xml = parser.parseFromString(xml, 'application/xml')
  this.isError = !!(this.xml.querySelector('error') && this.xml.querySelector('error').children && this.xml.querySelector('error').children.length)
  if (!this.isError) {
    this.pullData()
  }
}

UploadResult.prototype.pullData = function () {
  const resultOk = this.xml.querySelector('result_ok')
  if (resultOk) {
    this.token = resultOk.querySelector('token') && resultOk.querySelector('token').textContent
    this.fileId = resultOk.querySelector('filename') && resultOk.querySelector('filename').textContent
    this.filename = resultOk.querySelector('origFilename') && resultOk.querySelector('origFilename').textContent
  }
}

UploadResult.prototype.asEntryParams = function () {
  return {
    entry1_name: this.filename,
    entry1_filename: this.fileId,
    entry1_realFilename: this.filename,
  }
}

export default UploadResult
