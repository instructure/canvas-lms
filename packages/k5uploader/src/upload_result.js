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

import XmlParser from './xml_parser'

function UploadResult() {
  this.xml = undefined
  this.isError = true
  this.token = undefined
  this.filename = ''
  this.fileId = -1
  this.xmlParser = new XmlParser()
}

UploadResult.prototype.parseXML = function(xml) {
  const $xml = this.xmlParser.parseXML(xml)
  this.isError = this.xmlParser.isError
  if (!this.xmlParser.isError) {
    this.pullData()
  }
}

UploadResult.prototype.pullData = function() {
  const $resultOk = this.xmlParser.find('result_ok')
  this.token = this.xmlParser.nodeText('token', $resultOk, true)
  this.fileId = this.xmlParser.nodeText('filename', $resultOk, true)
  this.filename = this.xmlParser.nodeText('origFilename', $resultOk)
}

UploadResult.prototype.asEntryParams = function() {
  return {
    entry1_name: this.filename,
    entry1_filename: this.fileId,
    entry1_realFilename: this.filename
  }
}

export default UploadResult
