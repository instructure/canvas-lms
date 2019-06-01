#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import _ from 'underscore'

export default class VeriCiteSettings

  constructor: (options = {}) ->
    @originalityReportVisibility = options.originality_report_visibility || 'immediate'
    @excludeQuoted = @normalizeBoolean(options.exclude_quoted)
    @excludeSelfPlag = @normalizeBoolean(options.exclude_self_plag)
    @storeInIndex = @normalizeBoolean(options.store_in_index)

  toJSON: =>
    originality_report_visibility: @originalityReportVisibility
    exclude_quoted: @excludeQuoted
    exclude_self_plag: @excludeSelfPlag
    store_in_index: @storeInIndex

  present: =>
    json = {}
    for own key,value of this
      json[key] = value
    json

  normalizeBoolean: (value) =>
    _.contains(["1", true, "true", 1], value)
