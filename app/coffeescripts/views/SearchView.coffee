define ['Backbone', 'jst/searchView'], (Backbone, template) ->

  ##
  # Base class for search/filter views. Simply wires up an
  # inputFilterView to fetch a collecion, which then renders the
  # collectionView. You will most certainly want a different template

  class SearchView extends Backbone.View

    @child 'inputFilterView', '.inputFilterView'

    @child 'collectionView', '.collectionView'

    template: template

    initialize: (options) ->
      super
      @collection = @collectionView.collection
      @attach()

    attach: ->
      @inputFilterView.on 'input', @fetchResults
      @inputFilterView.on 'enter', @fetchResults

    fetchResults: (query) =>
      @collection.setParam 'search_term', query
      @collection.fetch()

