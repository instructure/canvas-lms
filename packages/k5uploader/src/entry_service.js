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
import mBus from './message_bus'
import XmlParser from './xml_parser'
import objectMerge from './object_merge'
import k5Options from './k5_options'

function EntryService() {
  this.xmlParser = new XmlParser()
}

EntryService.prototype.addEntry = function(allParams) {
  this.formData = objectMerge(allParams)
  this.createEntryRequest()
}

EntryService.prototype.createEntryRequest = function() {
  const data = this.formData
  data.kalsig = signatureBuilder(data)

  this.xhr = new XMLHttpRequest()
  this.xhr.open('GET', k5Options.entryUrl + urlParams(data))
  this.xhr.requestType = 'xml'
  this.xhr.onload = this.onEntryRequestLoaded.bind(this)
  this.xhr.send(data)
}

EntryService.prototype.onEntryRequestLoaded = function(e) {
  this.xmlParser.parseXML(this.xhr.response)
  var ent = this.xmlParser.findRecursive('result:entries:entry1_')
  if (ent) {
    var ent = {
      id: ent.find('id').text(),
      type: ent.find('type').text(),
      title: ent.find('name').text(),
      context_code: ent.find('partnerData').text(),
      mediaType: ent.find('mediatype').text(),
      entryId: ent.find('id').text(),
      userTitle: undefined
    }
    mBus.dispatchEvent('Entry.success', ent, this)
  } else {
    mBus.dispatchEvent('Entry.fail', this.xhr.response, this)
  }
}

export default EntryService
