#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'underscore'
  '../collections/PaginatedCollection'
  '../models/Message'
], (_, PaginatedCollection, Message) ->

  class MessageCollection extends PaginatedCollection

    model: Message

    url: '/api/v1/conversations'

    params:
      scope: 'inbox'

    comparator: (a, b) ->
      dates = _.map [a, b], (message) ->
        message.timestamp().getTime()
      return -1 if dates[0] > dates[1]
      return  1 if dates[1] > dates[0]
      return 0

    selectRange: (model) ->
      newPos = @indexOf(model)
      lastSelected = _.last(@view.selectedMessages)
      @.each (x) -> x.set('selected', false)
      lastPos = @indexOf(lastSelected)
      range = @slice(Math.min(newPos, lastPos), Math.max(newPos, lastPos)+1)
      # the anchor needs to stay at the end
      range.reverse() if newPos > lastPos
      _.each range, (x) -> x.set('selected', true)
