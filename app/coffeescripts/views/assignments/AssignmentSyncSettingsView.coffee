#
# Copyright (C) 2017 - present Instructure, Inc.
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
  'jquery'
  'i18n!assignments'
  'underscore'
  'compiled/views/DialogFormView'
  'jst/EmptyDialogFormWrapper'
  'jst/assignments/AssignmentSyncSettings'
], ($, I18n, _, DialogFormView, wrapper, assignmentSyncSettingsTemplate) ->

  class AssignmentSyncSettingsView extends DialogFormView
    template: assignmentSyncSettingsTemplate
    wrapperTemplate: wrapper

    defaults:
      width: 600
      height: 300
      collapsedHeight: 300

    events: _.extend({}, @::events,
      'click .dialog_closer': 'cancel'
    )

    @optionProperty 'userIsAdmin'
    @optionProperty 'viewToggle'

    initialize: ->
      @viewToggle = false
      super

    cannotDisableSync: ->
      @userIsAdmin

    openDisableSync: ->
      if @viewToggle
        @openAgain()
      else
        @viewToggle = true
        @open()

    # Stubbed for ajax call
    submit: (event) ->
      if @canDisableSync()
        super(event)
      else
        event?.preventDefault()

    cancel: ->
      @close()

    # Stubbed to handle endpoint
    # response and display
    # proper message
    onSaveSuccess: ->
      super
      @tirgger(true)

    toJSON: ->
      data = super
      data.course
      data
