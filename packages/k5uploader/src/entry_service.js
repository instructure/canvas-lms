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
import mBus from './message_bus'
import objectMerge from './object_merge'
import k5Options from './k5_options'

function EntryService() {}

EntryService.prototype.addEntry = function (allParams) {
  this.formData = objectMerge(allParams)
  this.createEntryRequest()
}

EntryService.prototype.createEntryRequest = function () {
  const data = this.formData
  data.kalsig = signatureBuilder(data)

  this.xhr = new XMLHttpRequest()
  this.xhr.open('GET', k5Options.entryUrl + urlParams(data))
  this.xhr.requestType = 'xml'
  this.xhr.onload = this.onEntryRequestLoaded.bind(this)
  this.xhr.send(data)
}

EntryService.prototype.parseRequest = function (xml) {
  const parser = new DOMParser()
  const parsedXml = parser.parseFromString(xml, "application/xml")
  const ent = parsedXml.querySelector("result > entries > entry1_")
  if (ent) {
    var entry = {
      id: ent.querySelector('id') && ent.querySelector('id').textContent,
      type: ent.querySelector('type') && ent.querySelector('type').textContent,
      title: ent.querySelector('name') && ent.querySelector('name').textContent,
      context_code: ent.querySelector('partnerData') && ent.querySelector('partnerData').textContent,
      mediaType: ent.querySelector('mediatype') && ent.querySelector('mediatype').textContent,
      entryId: ent.querySelector('id') && ent.querySelector('id').textContent,
      userTitle: undefined,
    }
    return entry
  }
  return null
}

EntryService.prototype.onEntryRequestLoaded = function (e) {
  const entry = this.parseRequest(this.xhr.response)
  if (entry) {
    mBus.dispatchEvent('Entry.success', entry, this)
  } else {
    mBus.dispatchEvent('Entry.fail', this.xhr.response, this)
  }
}

export default EntryService
