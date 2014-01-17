define [
  'Backbone'
  'jquery' 
  'compiled/views/PaginatedCollectionView'  
  'compiled/views/InputFilterView'
  'compiled/views/accounts/UserView'
  'compiled/views/accounts/admin_tools/UserDateRangeSearchFormView'
  'compiled/collections/AuthLoggingCollection'
  'compiled/views/accounts/admin_tools/AuthLoggingItemView'
  'jst/accounts/admin_tools/authLoggingSearchResults'
  'jst/accounts/usersList'
  'jst/accounts/admin_tools/authLoggingContentPane'
], (
  Backbone,
  $,
  PaginatedCollectionView,
  InputFilterView,
  UserView,
  UserDateRangeSearchFormView,
  AuthLoggingCollection,
  AuthLoggingItemView,
  authLoggingResultsTemplate,
  usersTemplate,
  template
) ->
  class AuthLoggingContentPaneView extends Backbone.View
    @child 'searchForm', '#authLoggingSearchForm'
    @child 'resultsView', '#authLoggingSearchResults'

    template: template

    constructor: (@options) ->
      @collection = new AuthLoggingCollection null
      super

      @searchForm = new UserDateRangeSearchFormView
        formName: 'logging'
        inputFilterView: new InputFilterView
          collection: @options.users
        usersView: new PaginatedCollectionView
          collection: @options.users
          itemView: UserView
          buffer: 1000
          template: usersTemplate
        collection: @collection
      @resultsView = new PaginatedCollectionView
        template: authLoggingResultsTemplate
        itemView: AuthLoggingItemView
        collection: @collection

    attach: ->
      @collection.on 'setParams', @fetch

    fetch: =>
      @collection.fetch().fail @onFail

    onFail: =>
      # Received a 404, empty the collection and don't let the paginated
      # view try to fetch more.
      @collection.reset()
      @resultsView.detachScroll()
