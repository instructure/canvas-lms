#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'i18n!calendar'
  '../calendar/EditAppointmentGroupDetails'
  'jst/calendar/editAppointmentGroup'
  'jqueryui/dialog'
], ($, I18n, EditAppointmentGroupDetails, editAppointmentGroupTemplate) ->

  dialog = $('<div id="edit_event"><div class="wrapper"></div>').appendTo('body').dialog
    autoOpen: false
    width: 'auto'
    resizable: false
    title: I18n.t('titles.edit_appointment_group', "Edit Appointment Group")
  # this is dumb, but it prevents the columns from wrapping when
  # the context selector drop down gets too long
  dialog.dialog('widget').find('#edit_event').css('overflow', 'visible')

  class EditAppointmentGroupDialog
    constructor: (@apptGroup, @contexts, @parentCloseCB) ->
      @currentContextInfo = null

    closeCB: (saved) =>
      dialog.dialog('close')
      @parentCloseCB(saved)

    show: =>
      @appointmentGroupsForm = new EditAppointmentGroupDetails(dialog.find(".wrapper"), @apptGroup, @contexts, @closeCB)

      buttons = if @apptGroup.workflow_state == 'active'
        [
          text: I18n.t 'save_changes', 'Save Changes'
          class: 'Button Button--primary'
          click: @appointmentGroupsForm.saveClick
        ]
      else
        [
          text: I18n.t 'save', 'Save'
          class: 'Button'
          click: @appointmentGroupsForm.saveWithoutPublishingClick
        ,
          text: I18n.t 'save_and_publish', 'Save & Publish'
          class: 'Button Button--primary'
          click: @appointmentGroupsForm.saveClick
        ]

      dialog.dialog('option', 'buttons', buttons).dialog('open')
