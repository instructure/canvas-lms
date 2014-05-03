define [
  'Backbone'
  'jquery'
  'jst/accounts/admin_tools/AdminTools'
  'jqueryui/tabs'
], (Backbone,$, template) -> 
  # This is the main container view that holds 
  # all of the tabs on the admin tools page.
  # It allows you to give it a tab property that should
  # look like this
  # tabs: 
  #   courseRestore  : true
  #   viewMessages   : true
  #   anotherTabName : true
  class AdminToolsView extends Backbone.View
    # Define children that use this backbone template.
    # @api custom backbone
    @child 'restoreContentPaneView', '#restoreContentPane'
    @child 'messageContentPaneView', '#commMessagesPane'
    @child 'loggingContentPaneView', '#loggingPane'
    @optionProperty 'tabs'

    template: template

    els: 
      '#adminToolsTabs' : '$adminToolsTabs'

    # Enable the tabs after items are loaded. 
    # @api custom backbone override
    afterRender: -> 
      @$adminToolsTabs.tabs()

    toJSON: (json) -> 
      json = super
      json.courseRestore = @tabs.courseRestore
      json.viewMessages = @tabs.viewMessages
      json.logging = @tabs.logging
      json

