define [
  'Backbone'
  'jquery'
  'compiled/views/accounts/admin_tools/AdminToolsView'
], (Backbone, $, AdminToolsView) -> 
  QUnit.module 'AdminToolsViewSpec',
    setup: -> 
      @admin_tools_view = new AdminToolsView
        restoreContentPaneView: new Backbone.View
        messageContentPaneView: new Backbone.View
        tabs:
          courseRestore: true
          viewMessages: true

      $('#fixtures').append @admin_tools_view.render().el

    teardown: -> 
      @admin_tools_view.remove()

  test "creates a new jquery tabs", -> 
    ok @admin_tools_view.$adminToolsTabs.data('tabs'), "There should be 2 tabs initialized"
