#
# Copyright (C) 2012 - present Instructure, Inc.
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
  '../collections/PaginatedCollection'
  '../models/DiscussionTopic'
  '../util/NumberCompare'
], ($, PaginatedCollection, DiscussionTopic, numberCompare) ->

  class DiscussionTopicsCollection extends PaginatedCollection

    model: DiscussionTopic

    comparator: @dateComparator

    @dateComparator: (a, b) ->
      aDate = new Date(a.get('last_reply_at')).getTime()
      bDate = new Date(b.get('last_reply_at')).getTime()

      if aDate < bDate
        1
      else if aDate > bDate
        -1
      else
        @idCompare(a, b)

    @positionComparator: (a, b) ->
      aPosition = a.get('position')
      bPosition = b.get('position')
      c = numberCompare(aPosition, bPosition)
      if c isnt 0 then c else @idCompare(a, b)

    idCompare: (a, b) ->
      numberCompare(parseInt(a.get('id')), parseInt(b.get('id')), descending: true)

    reorderURL: -> @url()+'/reorder'

    reorder: ->
      @each (model, i) ->
        model.set(position: i+1)
      ids = @pluck('id')
      $.post @reorderURL(), order: ids
      @reset @models
