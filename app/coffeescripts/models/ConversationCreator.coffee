#
# Copyright (C) 2017 - present Instructure, Inc.
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

define [
  'jquery'
  'lodash'
  '../models/Conversation'
], ($, _, Conversation) ->

  class ConversationCreator
    constructor: (opts) ->
      @chunkSize = opts.chunkSize || 100

    save: (data, saveOpts) ->
      data.context_code = ENV.context_asset_string
      xhrs = _.chunk(data.recipients, @chunkSize).map (chunk) ->
        chunkData = Object.assign({}, data, { recipients: chunk })
        (new Conversation).save(chunkData, saveOpts)
      $.when.apply($, xhrs)

    # we can validate the full data set in one go
    validate: (attrs, options) ->
      (new Conversation).validate(attrs, options)
