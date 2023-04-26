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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import _ from 'underscore'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import wrapper from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import assignmentSyncSettingsTemplate from '../../jst/AssignmentSyncSettings.handlebars'
import '@canvas/rails-flash-notifications'

I18n = useI18nScope('AssignmentSyncSettingsView')

export default class AssignmentSyncSettingsView extends DialogFormView
  template: assignmentSyncSettingsTemplate
  wrapperTemplate: wrapper

  defaults:
    width: 600
    height: 300
    collapsedHeight: 300

  events: _.extend({}, @::events,
    'click .dialog_closer': 'cancel'
  )

  @optionProperty 'viewToggle'
  @optionProperty 'sisName'

  initialize: ->
    @viewToggle = false
    super

  openDisableSync: ->
    if @viewToggle
      @openAgain()
    else
      @viewToggle = true
      @open()

  currentGradingPeriod: ->
    selected_id = $("#grading_period_selector").children(":selected").attr("id")
    id = if selected_id == undefined then '' else selected_id.split("_").pop()
    id

  submit: (event) ->
    event?.preventDefault()
    success_message = I18n.t('Sync to %{name} successfully disabled', name: @sisName)
    error_message = I18n.t('Disabling Sync to %{name} failed', name: @sisName)
    $.ajaxJSON '/api/sis/courses/' +
                @model.id +
                '/disable_post_to_sis', 'PUT',
                grading_period_id: @currentGradingPeriod(),
                ((data) ->
                  $.flashMessage success_message
                  setTimeout(window.location.reload(true))
                ), ->
                  $.flashError error_message

  cancel: ->
    @close()

  toJSON: ->
    data = super
    data.sisName = @sisName
    data
