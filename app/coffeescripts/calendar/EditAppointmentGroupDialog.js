/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import I18n from 'i18n!calendar'
import EditAppointmentGroupDetails from '../calendar/EditAppointmentGroupDetails'
import 'jqueryui/dialog'

const dialog = $('<div id="edit_event"><div class="wrapper"></div>')
  .appendTo('body')
  .dialog({
    autoOpen: false,
    width: 'auto',
    resizable: false,
    title: I18n.t('titles.edit_appointment_group', 'Edit Appointment Group')
  })
// this is dumb, but it prevents the columns from wrapping when
// the context selector drop down gets too long
dialog
  .dialog('widget')
  .find('#edit_event')
  .css('overflow', 'visible')

export default class EditAppointmentGroupDialog {
  constructor(apptGroup, contexts, parentCloseCB) {
    this.apptGroup = apptGroup
    this.contexts = contexts
    this.parentCloseCB = parentCloseCB
    this.currentContextInfo = null
  }

  closeCB = saved => {
    dialog.dialog('close')
    return this.parentCloseCB(saved)
  }

  show = () => {
    this.appointmentGroupsForm = new EditAppointmentGroupDetails(
      dialog.find('.wrapper'),
      this.apptGroup,
      this.contexts,
      this.closeCB
    )

    const buttons =
      this.apptGroup.workflow_state === 'active'
        ? [
            {
              text: I18n.t('save_changes', 'Save Changes'),
              class: 'Button Button--primary',
              click: this.appointmentGroupsForm.saveClick
            }
          ]
        : [
            {
              text: I18n.t('save', 'Save'),
              class: 'Button',
              click: this.appointmentGroupsForm.saveWithoutPublishingClick
            },
            {
              text: I18n.t('save_and_publish', 'Save & Publish'),
              class: 'Button Button--primary',
              click: this.appointmentGroupsForm.saveClick
            }
          ]

    return dialog.dialog('option', 'buttons', buttons).dialog('open')
  }
}
