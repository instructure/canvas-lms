define [
  'i18n!course_users'
  'jquery'
  'Backbone'
  'jst/searchView'
  'compiled/views/ValidatedMixin'
  'jquery.instructure_forms'
  'vendor/jquery.placeholder'
], (I18n, $, Backbone, template, ValidatedMixin) ->

  ##
  # Base class for search/filter views. Simply wires up an
  # inputFilterView to fetch a collecion, which then renders the
  # collectionView. You will most certainly want a different template

  class SearchView extends Backbone.View

    @mixin ValidatedMixin

    defaults:

      ##
      # Name of the parameter to add to the query string

      paramName: 'search_term'

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

    initialize: (options) ->
      super
      @collection = @collectionView.collection
      @attach()

    attach: ->
      @inputFilterView.on 'input', @fetchResults

    afterRender: ->
      @$el.placeholder()

    fetchResults: (query) =>
      if query is ''
        @collection.deleteParam @options.paramName
      # this might not be general :\
      else if query.length < 3
        return
      else
        @collection.setParam @options.paramName, query
      @lastRequest?.abort()
      @lastRequest = @collection.fetch().fail @onFail

    onFail: (xhr) =>
      return if xhr.statusText is 'abort'
      parsed = $.parseJSON xhr.responseText
      message = if parsed.message is "search_term of 3 or more characters is required"
        I18n.t('greater_than_three', 'Please enter a search term with three or more characters')
      else
        I18n.t('unknown_error', 'Something went wrong with your search, please try again.')
      @showErrors inputFilter: [{message}]

    toJSON: ->
      collection: @collection

