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
  '../util/mixin'
  'underscore'
], (mixin, _) ->

  ##
  # Mixin to make your (Paginated)CollectionView filterable on the client
  # side. Just put an <input class="filterable> in your template, mix in
  # this mixin, and you're good to go.
  #
  # Filterable simple hides the item views in the DOM, keeping stuff nice
  # and fast (no need to fetch from the server, no need to re-render
  # anything)
  Filterable =

    els:
      '.filterable': '$filter'
      '.no-results': '$noResults'

    defaults:
      filterColumns: ['name']

    afterRender: ->
      @$filter?.on 'input', => @setFilter @$filter.val()
      @$filter?.trigger 'input'

    setFilter: (filter) ->
      @filter = filter.toLowerCase()
      for model in @collection.models
        model.trigger 'filterOut', @filterOut(model)
      # show a "no results" message if there are items but they are all
      # filtered out
      @$noResults.toggleClass 'hidden', not (@filter and not @collection.fetchingPage and @collection.length > 0 and @$list.children(':visible').length is 0)

    attachItemView: (model, view) ->
      filterView = (filtered) ->
        view.$el.toggleClass 'hidden', filtered
      model.on 'filterOut', filterView
      filterView @filterOut(model)

    ##
    # Return whether or not the model (and its view) should be hidden
    # based on the current filter
    filterOut: (model) ->
      return false if not @filter
      return false if not @options.filterColumns.length
      return false if _.any @options.filterColumns, (col) =>
        model.get(col).toLowerCase().indexOf(@filter) >= 0
      true

