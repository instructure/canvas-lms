define [
  'Backbone'
  'jquery'
  'jst/accounts/admin_tools/authLoggingContentPane'
], (Backbone, $, template) ->
  class AuthLoggingContentPaneView extends Backbone.View
    @child 'searchForm', '#authLoggingSearchForm'
    @child 'resultsView', '#authLoggingSearchResults'

    template: template

    attach: ->
      @collection.on 'setParams', @fetch

    fetch: =>
      @collection.fetch().fail @onFail

    onFail: =>
      # Received a 404, empty the collection and don't let the paginated
      # view try to fetch more.
      @collection.reset()
      @resultsView.detachScroll()
