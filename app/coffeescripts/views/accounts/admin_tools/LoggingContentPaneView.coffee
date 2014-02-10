define [
  'Backbone'
  'jquery'
  'compiled/views/accounts/admin_tools/AuthLoggingContentPaneView'
  'compiled/views/accounts/admin_tools/GradeChangeLoggingContentView'
  'jst/accounts/admin_tools/loggingContentPane'
], (
  Backbone, 
  $,
  AuthLoggingContentPaneView,
  GradeChangeLoggingContentView,
  template
) ->
  class LoggingContentPaneView extends Backbone.View
    @child 'authentication', '#loggingAuthentication'
    @child 'gradeChange', '#loggingGradeChange'

    events:
      'change #loggingType': 'onTypeChange'

    template: template

    constructor: (@options) ->
      super
      @permissions = @options.permissions
      @authentication = @initAuthLogging()
      @gradeChange = @initGradeChangeLogging()

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

    initGradeChangeLogging: ->
      unless @permissions.grade_change
        return new Backbone.View

      return new GradeChangeLoggingContentView
        users: @options.users