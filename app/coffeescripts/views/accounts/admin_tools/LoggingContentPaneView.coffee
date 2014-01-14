define [
  'Backbone'
  'jquery'
  'compiled/views/accounts/admin_tools/AuthLoggingContentPaneView'
  'jst/accounts/admin_tools/loggingContentPane'
], (
  Backbone, 
  $,
  AuthLoggingContentPaneView,
  template
) ->
  class LoggingContentPaneView extends Backbone.View
    @child 'authentication', '#loggingAuthentication'

    events:
      'change #loggingType': 'onTypeChange'

    template: template

    constructor: (@options) ->
      super
      @permissions = @options.permissions
      @authentication = @initAuthLogging()

    afterRender: ->
      @$el.find(".loggingTypeContent").hide()

    toJSON: ->
      @permissions

    onTypeChange: (e) ->
      $target = $(e.target)
      value = $target.val()
      @$el.find(".loggingTypeContent").hide()
      @$el.find(value).show().find("input").first().focus()
      $target.find('[value=default]').remove()

    initAuthLogging: ->
      unless @permissions.authentication
        return new Backbone.View

      return new AuthLoggingContentPaneView
        users: @options.users