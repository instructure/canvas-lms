#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  '../../../models/CreateUserList'
  'underscore'
  'i18n!create_users_view'
  '../../DialogFormView'
  'jst/courses/roster/createUsers'
  'jst/EmptyDialogFormWrapper'
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

    focusX: ->
      $('.ui-dialog-titlebar-close', @el.parentElement).focus()

