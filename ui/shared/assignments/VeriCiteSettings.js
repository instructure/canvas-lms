/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

const hasProp = {}.hasOwnProperty

function VeriCiteSettings(options) {
  if (options == null) {
    options = {}
  }
  this.normalizeBoolean = this.normalizeBoolean.bind(this)
  this.present = this.present.bind(this)
  this.toJSON = this.toJSON.bind(this)
  this.originalityReportVisibility = options.originality_report_visibility || 'immediate'
  this.excludeQuoted = this.normalizeBoolean(options.exclude_quoted)
  this.excludeSelfPlag = this.normalizeBoolean(options.exclude_self_plag)
  this.storeInIndex = this.normalizeBoolean(options.store_in_index)
}

VeriCiteSettings.prototype.toJSON = function () {
  return {
    originality_report_visibility: this.originalityReportVisibility,
    exclude_quoted: this.excludeQuoted,
    exclude_self_plag: this.excludeSelfPlag,
    store_in_index: this.storeInIndex,
  }
}

VeriCiteSettings.prototype.present = function () {
  const json = {}
  const ref = this
  for (const key in ref) {
    if (!hasProp.call(ref, key)) continue
    const value = ref[key]
    json[key] = value
  }
  return json
}

VeriCiteSettings.prototype.normalizeBoolean = function (value) {
  return ['1', true, 'true', 1].includes(value)
}

export default VeriCiteSettings
