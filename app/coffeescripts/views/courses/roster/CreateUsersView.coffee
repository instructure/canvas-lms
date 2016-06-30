define [
  'compiled/models/CreateUserList'
  'underscore'
  'i18n!create_users_view'
  'compiled/views/DialogFormView'
  'jst/courses/roster/createUsers'
  'jst/EmptyDialogFormWrapper'
  'vendor/jquery.placeholder'
], (CreateUserList, _, I18n, DialogFormView, template, wrapper) ->

  class CreateUsersView extends DialogFormView
    @optionProperty 'rolesCollection'
    @optionProperty 'courseModel'

    defaults:
      width: 700
      height: 500

    els:
      '#privileges': '$privileges'
      '#user_list_textarea': '$textarea'

    events: _.extend({}, @::events,
      'click .createUsersStartOver': 'startOver'
      'click .createUsersStartOverFrd': 'startOverFrd'
      'change #role_id': 'changeEnrollment'
      'click #role_id': 'changeEnrollment'
      'click .dialog_closer': 'close'
    )

    template: template

    wrapperTemplate: wrapper

    initialize: ->
      @model ?= new CreateUserList
      super

    attach: ->
      @model.on 'change:step', @render, this
      @model.on 'change:step', @focusX, this

    changeEnrollment: (event) ->
      @model.set 'role_id', event.target.value

    openAgain: ->
      @startOverFrd()
      super
      @focusX()

    hasUsers: ->
      @model.get('users')?.length

    onSaveSuccess: ->
      @model.incrementStep()
      if @model.get('step') is 3
        role = @rolesCollection.where({id: @model.get('role_id')})[0]
        role?.increment 'count', @model.get('users').length
        newUsers = @model.get('users').length
        @courseModel?.increment 'pendingInvitationsCount', newUsers

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

    toJSON: =>
      json = super
      json.course_section_id = "#{json.course_section_id}"
      json.limit_privileges_to_course_section = json.limit_privileges_to_course_section == true ||
                                                    json.limit_privileges_to_course_section == "1"
      json

    afterRender: ->
      @$('[placeholder]').placeholder()

    focusX: ->
      $('.ui-dialog-titlebar-close', @el.parentElement).focus()

