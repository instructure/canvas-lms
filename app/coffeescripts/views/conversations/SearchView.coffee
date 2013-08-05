define [
  'underscore'
  'Backbone'
  'compiled/views/conversations/AutocompleteView'
], (_, {View}, AutocompleteView) ->

  class SearchView extends View

    els:
      '#search-autocomplete': '$autocomplete'

    events:
      'click #search-btn': 'onBtnClick'

    initialize: ->
      super
      @render()
      @autocompleteView = new AutocompleteView(el: @$autocomplete, single: true).render()
      @autocompleteView.on('changeToken', @onSearch)
      @autocompleteView.on('disabled', @onDisabled)
      @autocompleteView.on('enabled', @onEnabled)

    onSearch: (tokens) =>
      @trigger('search', tokens)

    onBtnClick: (e) ->
      @autocompleteView._fetchResults(true)
      @autocompleteView.$input.focus()

    onDisabled: ->
      @$el.find('#search-btn').prop('disabled', true)

    onEnabled: ->
      @$el.find('#search-btn').prop('disabled', false)
