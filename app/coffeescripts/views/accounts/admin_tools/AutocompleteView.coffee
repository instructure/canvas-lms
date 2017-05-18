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
  'jquery'
  'jst/accounts/admin_tools/autocomplete'
  'jqueryui/autocomplete'
], (_, Backbone, $, template) ->
  class AutocompleteView extends Backbone.View
    template: template

    els:
      '[data-name=autocomplete_search_term]': '$searchTerm'
      '[data-name=autocomplete_search_value]': '$searchValue'

    constructor: (@options) ->
      @collection = @options.collection
      super

      @options.minLength ||= 3
      @options.labelProperty ||= 'name'
      @options.valueProperty ||= 'id'
      @options.fieldName ||= @options.valueProperty
      @options.placeholder ||= @options.fieldName
      @options.sourceParameters ||= {}

    toJSON: ->
      @options

    afterRender: ->
      @$searchTerm.autocomplete
        minLength: @options.minLength
        select: $.proxy(@autocompleteSelect, @)
        source: $.proxy(@autocompleteSource, @)
        change: $.proxy(@autocompleteSelect, @)

    autocompleteSource: (request, response) ->
      @$searchTerm.addClass("loading")
      params = data: @options.sourceParameters
      params.data.search_term = request.term
      labelProperty = @options.labelProperty
      success = ->
        items = @collection.map (item) ->
          label = labelProperty(item) if $.isFunction(labelProperty)
          label ||= item.get(labelProperty)
          model: item
          label: label
        @$searchTerm.removeClass("loading")
        response(items)
      @collection.fetch(params).success $.proxy(success, @)

    autocompleteSelect: (event, ui) ->
      if ui.item && ui.item.value
        @$searchValue.val(ui.item.model.id)
      else
        @$searchValue.val(null)
