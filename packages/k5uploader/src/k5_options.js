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

import defaults from './defaults'

function K5Options() {}

K5Options.prototype.setOptions = function (options) {
  this.mergeDefaults(options)
}

K5Options.prototype.mergeDefaults = function (options) {
  this.allowedMediaTypes = ['video', 'audio']
  this.sessionUrl = '/api/v1/services/kaltura_session'
  this.uploadUrl = ''
  this.entryUrl = ''
  this.uiconfUrl = ''
  this.entryDefaults = {
    partnerData: "{'context_code': 'some_course_num', 'root_account'_id':1}",
    conversionProfile: 2,
    source: 1,
    kshow_id: -1,
    quick_edit: true,
  }
  defaults('allowedMediaTypes', this, options)
  defaults('sessionUrl', this, options)
  defaults('uploadUrl', this, options)
  defaults('entryUrl', this, options)
  defaults('uiconfUrl', this, options)
  defaults('partnerData', this.entryDefaults, options.entryDefaults)
  defaults('conversionProfile', this.entryDefaults, options.entryDefaults)
  defaults('source', this.entryDefaults, options.entryDefaults)
  defaults('kshow_id', this.entryDefaults, options.entryDefaults)
  defaults('quick_edit', this.entryDefaults, options.entryDefaults)
}

K5Options.prototype.asEntryParams = function () {
  return {
    entry1_partnerData: this.entryDefaults.partnerData,
    entry1_conversionProfile: this.entryDefaults.conversionProfile,
    entry1_source: this.entryDefaults.source,
    kshow_id: this.entryDefaults.kshow_id,
    quick_edit: this.entryDefaults.quick_edit,
  }
}

export default new K5Options()
