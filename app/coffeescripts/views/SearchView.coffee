define [
  'jquery'
  'Backbone'
  'jst/searchView'
  'compiled/views/SearchMixin'
], ($, Backbone, template, SearchMixin) ->

  ##
  # Base class for search/filter views. Simply wires up an
  # inputFilterView to fetch a collecion, which then renders the
  # collectionView. You will most certainly want a different template

  class SearchView extends Backbone.View

    @mixin SearchMixin

    ##
    # An InputFilterView

    @child 'inputFilterView', '.inputFilterView'

    ##
    # A CollectionView (and its sub-classes that don't break the
    # substitution rule like PaginatedCollectionView)

    @child 'collectionView', '.collectionView'

    ##
    # You probably don't want this template, but need the elements
    # found therein.

    template: template

    toJSON: ->
      collection: @collection

