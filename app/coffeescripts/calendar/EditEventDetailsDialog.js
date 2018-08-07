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
import _ from 'underscore'
import EditCalendarEventDetails from '../calendar/EditCalendarEventDetails'
import EditAssignmentDetails from '../calendar/EditAssignmentDetails'
import EditApptCalendarEventDialog from '../calendar/EditApptCalendarEventDialog'
import EditAppointmentGroupDetails from '../calendar/EditAppointmentGroupDetails'
import EditPlannerNoteDetails from '../calendar/EditPlannerNoteDetails'
import editEventTemplate from 'jst/calendar/editEvent'
import 'jqueryui/dialog'
import 'jqueryui/tabs'

const dialog = $('<div id="edit_event"><div /></div>')
  .appendTo('body')
  .dialog({
    autoOpen: false,
    width: 'auto',
    resizable: false,
    title: I18n.t('titles.edit_event', 'Edit Event')
  })

export default class EditEventDetailsDialog {
  constructor(event, betterScheduler) {
    this.event = event
    this.betterScheduler = betterScheduler
    this.currentContextInfo = null
    dialog.on('dialogclose', this.dialogClose)
  }

  contextInfoForCode(code) {
    return this.event.possibleContexts().find(context => context.asset_string === code)
  }

  setupTabs = () => {
    // Set up the tabbed view of the dialog
    const tabs = dialog.find('#edit_event_tabs')

    tabs.tabs().bind('tabsselect', (event, ui) =>
      $(ui.panel)
        .closest('.tab_holder')
        .data('form-widget')
        .activate()
    )

    if (this.event.eventType === 'calendar_event') {
      tabs.tabs('select', 0)
      tabs.tabs('remove', 2)
      tabs.tabs('remove', 1)
      if (this.canManageAppointments()) tabs.tabs('remove', 3)
      this.calendarEventForm.activate()
    } else if (this.event.eventType.match(/assignment/)) {
      tabs.tabs('select', 1)
      tabs.tabs('remove', 2)
      tabs.tabs('remove', 0)
      if (this.canManageAppointments()) tabs.tabs('remove', 3)
      this.assignmentDetailsForm.activate()
    } else if (this.event.eventType.match(/appointment/) && this.canManageAppointments()) {
      tabs.tabs('select', 3)
      tabs.tabs('remove', 2)
      tabs.tabs('remove', 1)
      tabs.tabs('remove', 0)
      this.appointmentGroupDetailsForm.activate()
    } else if (this.event.eventType === 'planner_note') {
      tabs.tabs('select', 2)
      tabs.tabs('remove', 3)
      tabs.tabs('remove', 1)
      tabs.tabs('remove', 0)
      this.plannerNoteDetailsForm.activate()
    } else {
      // don't show To Do tab if the planner isn't enabled
      if (!ENV.STUDENT_PLANNER_ENABLED) tabs.tabs('remove', 2)

      // don't even show the assignments tab if the user doesn't have
      // permission to create them
      const can_create_assignments = _.any(
        this.event.allPossibleContexts,
        c => c.can_create_assignments
      )
      if (!can_create_assignments) tabs.tabs('remove', 1)

      this.calendarEventForm.activate()
    }
  }

  contextChange = newContext => {
    // Update the style of the dialog box to reflect the current context
    dialog.removeClass(dialog.data('group_class'))
    dialog.addClass(`group_${newContext}`).data('group_class', `group_${newContext}`)
    if (this.calendarEventForm) this.calendarEventForm.setContext(newContext)
    if (this.assignmentDetailsForm) this.assignmentDetailsForm.setContext(newContext)
  }

  closeCB = () => dialog.dialog('close')

  dialogClose = () => {
    if (this.oldFocus != null) {
      this.oldFocus.focus()
      return (this.oldFocus = null)
    }
  }

  canManageAppointments = () => {
    if (
      ENV.CALENDAR.BETTER_SCHEDULER &&
      _.some(this.event.allPossibleContexts, c => c.can_create_appointment_groups) &&
      (this.event.eventType.match(/appointment/) || this.event.eventType.match(/generic/))
    ) {
      return true
    }
    return false
  }

  show = () => {
    if (this.event.isAppointmentGroupEvent()) {
      return new EditApptCalendarEventDialog(this.event).show()
    } else {
      let formHolder
      const html = editEventTemplate({showAppointments: this.canManageAppointments()})
      dialog.children().replaceWith(html)

      if (this.event.isNewEvent() || this.event.eventType === 'calendar_event') {
        formHolder = dialog.find('#edit_calendar_event_form_holder')
        this.calendarEventForm = new EditCalendarEventDetails(
          formHolder,
          this.event,
          this.contextChange,
          this.closeCB
        )
        formHolder.data('form-widget', this.calendarEventForm)
      }

      if (this.event.isNewEvent() || this.event.eventType.match(/assignment/)) {
        this.assignmentDetailsForm = new EditAssignmentDetails(
          $('#edit_assignment_form_holder'),
          this.event,
          this.contextChange,
          this.closeCB
        )
        dialog.find('#edit_assignment_form_holder').data('form-widget', this.assignmentDetailsForm)
      }

      if (this.event.isNewEvent() || this.event.eventType === 'planner_note') {
        formHolder = dialog.find('#edit_planner_note_form_holder')
        this.plannerNoteDetailsForm = new EditPlannerNoteDetails(
          formHolder,
          this.event,
          this.contextChange,
          this.closeCB
        )
        formHolder.data('form-widget', this.plannerNoteDetailsForm)
      }

      if (this.event.isNewEvent() && this.canManageAppointments()) {
        const group = {
          context_codes: [],
          sub_context_codes: []
        }
        this.appointmentGroupDetailsForm = new EditAppointmentGroupDetails(
          $('#edit_appointment_group_form_holder'),
          group,
          _.filter(this.event.allPossibleContexts, c => c.can_create_appointment_groups),
          this.closeCB,
          this.event,
          this.betterScheduler
        )
        dialog
          .find('#edit_appointment_group_form_holder')
          .data('form-widget', this.appointmentGroupDetailsForm)
      }

      this.setupTabs()

      // TODO: select the tab that should be active

      this.oldFocus = document.activeElement
      dialog.dialog('open')
    }
  }
}
