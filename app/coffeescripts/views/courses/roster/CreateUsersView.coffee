define [
  'compiled/models/CreateUserList'
  'underscore'
  'i18n!create_users_view'
  'compiled/views/DialogFormView'
  'jst/courses/roster/createUsers'
  'jst/courses/roster/createUsersWrapper'
  'vendor/jquery.placeholder'
], (CreateUserList, _, I18n, DialogFormView, template, wrapper) ->

  class CreateUsersView extends DialogFormView

    defaults:
      width: 700
      height: 500

    els:
      '#privileges': '$privileges'
      '#user_list_textarea': '$textarea'

    events: _.extend({}, @::events,
      'click .createUsersStartOver': 'startOver'
      'click .createUsersStartOverFrd': 'startOverFrd'
      'change #enrollment_type': 'changeEnrollment'
      'click #enrollment_type': 'changeEnrollment'
      'click .dialog_closer': 'close'
    )

    template: template

    wrapperTemplate: wrapper

    initialize: ->
      @model ?= new CreateUserList
      super

    attach: ->
      @model.on 'change:step', @render, this
      @model.on 'change:enrollment_type', @maybeShowPrivileges

    maybeShowPrivileges: =>
      if @model.get('enrollment_type') in ['TeacherEnrollment', 'TaEnrollment']
        @$privileges.show()
      else
        @$privileges.hide()

    changeEnrollment: (event) ->
      @model.set 'enrollment_type', event.target.value

    openAgain: ->
      @startOverFrd()
      super

    hasUsers: ->
      @model.get('users')?.length

    onSaveSuccess: ->
      @model.incrementStep()

    validateBeforeSave: (data) ->
      if @model.get('step') is 1 and !data.user_list
        user_list: [{
          type: 'required'
          message: I18n.t('required', 'Please enter some email addresses')
        }]
      else
        {}

    startOver: ->
      @model.startOver()

    startOverFrd: ->
      @model.startOver()
      @$textarea?.val ''

    afterRender: ->
      @$('[placeholder]').placeholder()
      @maybeShowPrivileges()

