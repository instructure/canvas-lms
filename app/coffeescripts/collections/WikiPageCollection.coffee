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
  '../collections/PaginatedCollection'
  '../models/WikiPage'
], (PaginatedCollection, WikiPage) ->

  class WikiPageCollection extends PaginatedCollection
    model: WikiPage

    initialize: ->
      super

      @sortOrders =
        title: 'asc'
        created_at: 'desc'
        updated_at: 'desc'
      @sortOrders.todo_date = 'desc' if ENV.STUDENT_PLANNER_ENABLED
      @setSortField 'title'

      # remove the front_page indicator on all other models when one is set
      @on 'change:front_page', (model, value) =>
        # only change other models if one of the models is being set to true
        return if !value

        for m in @filter((m) -> !!m.get('front_page'))
          m.set('front_page', false) if m != model

    sortByField: (sortField, sortOrder=null) ->
      @setSortField sortField, sortOrder
      @fetch()

    setSortField: (sortField, sortOrder=null) ->
      throw "#{sortField} is not a valid sort field" if @sortOrders[sortField] == undefined

      # toggle the sort order if no sort order is specified and the sort field is the current sort field
      if !sortOrder && @currentSortField == sortField
        sortOrder = if @sortOrders[sortField] == 'asc' then 'desc' else 'asc'

      @currentSortField = sortField
      @sortOrders[@currentSortField] = sortOrder if sortOrder

      @setParams
        sort: @currentSortField
        order: @sortOrders[@currentSortField]

      @trigger 'sortChanged', @currentSortField, @sortOrders
