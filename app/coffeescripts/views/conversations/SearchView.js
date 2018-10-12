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
  'Backbone'
  '../conversations/AutocompleteView'
], (_, {View}, AutocompleteView) ->

  class SearchView extends View

    els:
      '#search-autocomplete': '$autocomplete'

    initialize: ->
      super
      @render()
      @autocompleteView = new AutocompleteView(el: @$autocomplete, single: true, excludeAll: true).render()
      @autocompleteView.on('changeToken', @onSearch)

    onSearch: (tokens) =>
      @trigger('search', _.map(tokens, (x)->"user_#{x}"))
