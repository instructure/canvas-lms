define [
  'underscore'
  'Backbone'
  'jquery'
  'jst/accounts/admin_tools/autocomplete'
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

    toJSON: ->
      @options

    afterRender: ->
      @$searchTerm.autocomplete
        minLength: @options.minLength
        source: $.proxy(@autocompleteSource, @)
        select: $.proxy(@autocompleteSelect, @)
        change: $.proxy(@autocompleteSelect, @)

    autocompleteSource: (request, response) ->
      @$searchTerm.addClass("loading")
      params = data:
        search_term: request.term
      labelProperty = @options.labelProperty
      valueProperty = @options.valueProperty
      success = ->
        items = @collection.map (item) ->
          model: item
          label: item.get(labelProperty)
        @$searchTerm.removeClass("loading")
        response(items)
      @collection.fetch(params).success $.proxy(success, @)

    autocompleteSelect: (event, ui) ->
      if ui.item && ui.item.value
        @$searchValue.val(ui.item.model.id)
      else
        @$searchValue.val(null)
