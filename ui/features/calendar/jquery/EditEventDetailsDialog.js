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
import {some, filter} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import EditCalendarEventDetails from './EditCalendarEventDetails'
import EditAssignmentDetails from '../backbone/views/EditAssignmentDetails'
import EditApptCalendarEventDialog from './EditApptCalendarEventDialog'
import EditAppointmentGroupDetails from './EditAppointmentGroupDetails'
import EditPlannerNoteDetails from '../backbone/views/EditPlannerNoteDetails'
import EditToDoItemDetails from '../backbone/views/EditToDoItemDetails'
import editEventTemplate from '../jst/editEvent.handlebars'
import 'jqueryui/dialog'
import 'jqueryui/tabs'

const I18n = useI18nScope('calendar')

const dialog = $('<div id="edit_event"><div /></div>')
  .appendTo('body')
  .dialog({
    autoOpen: false,
    width: 'auto',
    resizable: false,
    title: I18n.t('titles.edit_event', 'Edit Event'),
    closeOnEscape: false,
    open: () =>
      document.addEventListener('keydown', EditEventDetailsDialog.prototype.handleKeyDown),
    close: () =>
      document.removeEventListener('keydown', EditEventDetailsDialog.prototype.handleKeyDown),
    modal: true,
    zIndex: 1000,
  })
  // these classes were added in dialog.js with the jquery 1.9.2 upgrade
  // they're not needed for this dialog and cause styling issues
  .removeClass('ui-dialog-content')
  .removeClass('ui-widget-content')

export default class EditEventDetailsDialog {
  constructor(event, useScheduler) {
    this.event = event
    this.useScheduler = useScheduler
    this.currentContextInfo = null
    dialog.on('dialogclose', this.dialogClose)
  }

  contextInfoForCode(code) {
    return this.event.possibleContexts().find(context => context.asset_string === code)
  }

  setupTabs = async () => {
    // Set up the tabbed view of the dialog
    const tabs = dialog.find('#edit_event_tabs')

    tabs
      .tabs()
      .bind('tabsselect', (event, ui) =>
        $(ui.panel).closest('.tab_holder').data('form-widget')?.activate()
      )

    // note: tabs should be removed in descending order, so numbers don't shift
    // from the indexes of the tabs in app/views/jst/calendar/editEvent.handlebars
    if (this.event.eventType === 'calendar_event') {
      tabs.tabs('select', 0)
      if (this.canManageAppointments()) tabs.tabs('remove', 4)
      tabs.tabs('remove', 3)
      tabs.tabs('remove', 2)
      tabs.tabs('remove', 1)
    } else if (this.event.eventType.match(/assignment/)) {
      tabs.tabs('select', 1)
      if (this.canManageAppointments()) tabs.tabs('remove', 4)
      tabs.tabs('remove', 3)
      tabs.tabs('remove', 2)
      tabs.tabs('remove', 0)
      this.assignmentDetailsForm.activate()
    } else if (this.event.eventType.match(/appointment/) && this.canManageAppointments()) {
      tabs.tabs('select', 4)
      tabs.tabs('remove', 3)
      tabs.tabs('remove', 2)
      tabs.tabs('remove', 1)
      tabs.tabs('remove', 0)
      this.appointmentGroupDetailsForm.activate()
    } else if (this.event.eventType === 'planner_note') {
      tabs.tabs('select', 2)
      tabs.tabs('remove', 4)
      tabs.tabs('remove', 3)
      tabs.tabs('remove', 1)
      tabs.tabs('remove', 0)
      this.plannerNoteDetailsForm.activate()
    } else if (this.event.eventType === 'todo_item') {
      tabs.tabs('select', 3)
      tabs.tabs('remove', 4)
      tabs.tabs('remove', 2)
      tabs.tabs('remove', 1)
      tabs.tabs('remove', 0)
      this.toDoItemDetailsForm.activate()
    } else {
      // to-do pages / discussions cannot be created on the calendar
      tabs.tabs('remove', 3)

      // don't show To Do tab if the planner isn't enabled or a user
      // managed calendar isn't selected
      let shouldRenderTODO = false
      const plannerNoteContexts = this.event.plannerNoteContexts()
      shouldRenderTODO = plannerNoteContexts && plannerNoteContexts.length

      if (!ENV.STUDENT_PLANNER_ENABLED || !shouldRenderTODO) {
        tabs.tabs('remove', 2)
      }

      // don't even show the assignments tab if the user doesn't have
      // permission to create them
      const can_create_assignments = some(
        this.event.allPossibleContexts,
        c => c.can_create_assignments
      )
      if (!can_create_assignments) tabs.tabs('remove', 1)
    }
  }

  contextChange(newContext) {
    // Update the style of the dialog box to reflect the current context
    dialog.removeClass(dialog.data('group_class'))
    dialog.addClass(`group_${newContext}`).data('group_class', `group_${newContext}`)
    if (this.calendarEventForm) this.calendarEventForm.setContext(newContext)
    if (this.assignmentDetailsForm) this.assignmentDetailsForm.setContext(newContext)
  }

  closeCB() {
    dialog.dialog('close')
  }

  handleKeyDown(e) {
    if (e.key !== 'Escape') return

    if (
      e.target.getAttribute('aria-expanded') === 'true' ||
      $('#custom-repeating-event-modal').length > 0
    ) {
      e.preventDefault()
    } else {
      dialog.dialog('close')
    }
  }

  dialogClose = () => {
    if (this.oldFocus != null) {
      this.oldFocus.focus()
      return (this.oldFocus = null)
    }
  }

  canManageAppointments = () => {
    if (
      ENV.CALENDAR.SHOW_SCHEDULER &&
      some(this.event.allPossibleContexts, c => c.can_create_appointment_groups) &&
      (this.event.eventType.match(/appointment/) || this.event.eventType.match(/generic/))
    ) {
      return true
    }
    return false
  }

  show = async () => {
    if (this.event.isAppointmentGroupEvent()) {
      return new EditApptCalendarEventDialog(this.event).show()
    } else {
      let formHolder
      const html = editEventTemplate({showAppointments: this.canManageAppointments()})
      dialog.children().replaceWith(html)

      if (this.event.isNewEvent() || this.event.eventType === 'calendar_event') {
        formHolder = document.getElementById('edit_calendar_event_form_holder')
        this.calendarEventForm = new EditCalendarEventDetails(
          formHolder,
          this.event,
          this.contextChange.bind(this),
          this.closeCB
        )
      }

      if (this.event.isNewEvent() || this.event.eventType.match(/assignment/)) {
        this.assignmentDetailsForm = new EditAssignmentDetails(
          $('#edit_assignment_form_holder'),
          this.event,
          this.contextChange.bind(this),
          this.closeCB
        )
        dialog.find('#edit_assignment_form_holder').data('form-widget', this.assignmentDetailsForm)
      }

      if (this.event.isNewEvent() || this.event.eventType === 'planner_note') {
        formHolder = dialog.find('#edit_planner_note_form_holder')
        this.plannerNoteDetailsForm = new EditPlannerNoteDetails(
          formHolder,
          this.event,
          this.contextChange.bind(this),
          this.closeCB
        )
        formHolder.data('form-widget', this.plannerNoteDetailsForm)
      }

      if (this.event.eventType === 'todo_item') {
        formHolder = dialog.find('#edit_todo_item_form_holder')
        this.toDoItemDetailsForm = new EditToDoItemDetails(
          formHolder,
          this.event,
          this.contextChange.bind(this),
          this.closeCB
        )
        formHolder.data('form-widget', this.toDoItemDetailsForm)
      }

      if (this.event.isNewEvent() && this.canManageAppointments()) {
        const group = {
          context_codes: [],
          sub_context_codes: [],
        }
        this.appointmentGroupDetailsForm = new EditAppointmentGroupDetails(
          $('#edit_appointment_group_form_holder'),
          group,
          filter(this.event.allPossibleContexts, c => c.can_create_appointment_groups),
          this.closeCB,
          this.event,
          this.useScheduler
        )
        dialog
          .find('#edit_appointment_group_form_holder')
          .data('form-widget', this.appointmentGroupDetailsForm)
      }

      await this.setupTabs()

      // TODO: select the tab that should be active

      this.oldFocus = document.activeElement
      dialog.dialog('open')
    }
  }
}
