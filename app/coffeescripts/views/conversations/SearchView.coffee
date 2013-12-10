define [
  'underscore'
  'Backbone'
  'compiled/views/conversations/AutocompleteView'
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
