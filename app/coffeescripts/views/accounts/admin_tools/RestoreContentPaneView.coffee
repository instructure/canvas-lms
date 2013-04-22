define [
  'Backbone'
  'jquery'
  'jst/accounts/admin_tools/RestoreContentPane'
], (Backbone,$, template) -> 
  class RestoreContentPaneView extends Backbone.View
    @child 'courseSearchFormView', '#courseSearchForm'
    @child 'courseSearchResultsView', '#courseSearchResults'

    template: template
