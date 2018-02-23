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
import _ from 'underscore'
import I18n from 'i18n!calendar'
import fcUtil from '../util/fcUtil'
import appointmentGroupListTemplate from 'jst/calendar/appointmentGroupList'
import schedulerRightSideAdminSectionTemplate from 'jst/calendar/schedulerRightSideAdminSection'
import EditAppointmentGroupDialog from '../calendar/EditAppointmentGroupDialog'
import MessageParticipantsDialog from '../calendar/MessageParticipantsDialog'
import deleteItemTemplate from 'jst/calendar/deleteItem'
import semanticDateRange from '../util/semanticDateRange'
import 'jquery.instructure_date_and_time'
import 'jqueryui/dialog'
import 'jquery.instructure_misc_plugins'
import 'vendor/jquery.ba-tinypubsub'
import 'spin.js/jquery.spin'
import '../behaviors/activate'

export default class Scheduler {
  constructor(selector, calendar) {
    this.calendar = calendar
    this.div = $(selector)
    this.contexts = this.calendar.contexts

    this.listDiv = this.div.find('.appointment-list')

    this.div.delegate('.view_calendar_link', 'click keyclick', this.viewCalendarLinkClick)
    this.div.activate_keyclick('.view_calendar_link')
    this.listDiv.delegate('.edit_link', 'click', this.editLinkClick)
    this.listDiv.delegate('.message_link', 'click', this.messageLinkClick)
    this.listDiv.delegate('.delete_link', 'click', this.deleteLinkClick)
    this.listDiv.delegate('.show_event_link', 'click keyclick', this.showEventLinkClick)
    this.listDiv.activate_keyclick('.show_event_link')

    if (this.canManageAGroup()) {
      this.div.addClass('can-manage')
      this.rightSideAdminSection = $(schedulerRightSideAdminSectionTemplate())
      this.rightSideAdminSection.find('.create_link').click(this.createClick)

      this.appointmentGroupContexts = _.filter(this.contexts, c => c.can_create_appointment_groups)
    }

    $.subscribe('CommonEvent/eventSaved', this.eventSaved)
    $.subscribe('CommonEvent/eventDeleted', this.eventDeleted)
  }

  createClick = jsEvent => {
    jsEvent.preventDefault()

    const group = {
      context_codes: [],
      sub_context_codes: []
    }

    this.createDialog = new EditAppointmentGroupDialog(
      group,
      this.appointmentGroupContexts,
      this.dialogCloseCB
    )
    return this.createDialog.show()
  }

  dialogCloseCB = saved => {
    if (saved) {
      this.calendar.dataSource.clearCache()
      return this.loadData()
    }
  }

  eventSaved = event => {
    if (this.active) {
      this.calendar.dataSource.clearCache()
      return this.loadData()
    }
  }

  eventDeleted = event => {
    if (this.active) {
      this.calendar.dataSource.clearCache()
      return this.loadData()
    }
  }

  toggleListMode(showListMode) {
    if (showListMode) {
      delete this.viewingGroup
      this.calendar.updateFragment({appointment_group_id: null})
      this.showList()
      if (this.canManageAGroup()) {
        $('#right-side .rs-section').hide()

        this.rightSideAdminSection.appendTo('#right-side')
      } else {
        $('#right-side-wrapper').hide()
      }
    } else {
      $('#right-side-wrapper').show()
      $('#right-side .rs-section')
        .not('#undated-events-section, #calendar-feed')
        .show()
      // we have to .detach() because of the css that puts lines under each .rs-section except the last,
      // if we just .hide() it would still be there so the :last-child selector would apply to it,
      // not the last _visible_ element
      this.rightSideAdminSection && this.rightSideAdminSection.detach()
    }
  }

  show = () => {
    $('#undated-events-section, #calendar-feed').hide()
    this.active = true
    this.div.show()
    this.loadData()
    return this.toggleListMode(true)
  }

  hide = () => {
    $('#undated-events-section, #calendar-feed').show()
    this.active = false
    this.div.hide()
    this.toggleListMode(false)
    this.calendar.displayAppointmentEvents = null
    $.publish('Calendar/restoreVisibleContextList')
  }

  canManageAGroup = () =>
    this.contexts.some(contextInfo => contextInfo.can_create_appointment_groups)

  loadData = () => {
    if (!this.loadingDeferred || (this.loadingDeferred && this.loadingDeferred.isResolved())) {
      this.loadingDeferred = new $.Deferred()
    }

    this.groups = {}
    if (this.loadingDiv == null) {
      this.loadingDiv = $('<div id="scheduler-loading" />')
        .appendTo(this.div)
        .spin()
    }

    return this.calendar.dataSource.getAppointmentGroups(this.canManageAGroup(), data => {
      data.forEach(group => (this.groups[group.id] = group))
      this.redraw()
      return this.loadingDeferred.resolve()
    })
  }

  redraw = () => {
    this.loadingDiv.hide()

    if (this.groups) {
      const groups = []
      for (const id in this.groups) {
        var group = this.groups[id]
        for (const timeId in group.reserved_times) {
          const time = group.reserved_times[timeId]
          time.formatted_time = semanticDateRange(time.start_at, time.end_at)
        }

        // look up the context names for the group
        group.contexts = _.filter(this.contexts, c => group.context_codes.includes(c.asset_string))

        group.published = group.workflow_state === 'active'

        groups.push(group)
      }

      const html = appointmentGroupListTemplate({
        appointment_groups: groups,
        canManageAGroup: this.canManageAGroup()
      })
      this.listDiv.find('.list-wrapper').html(html)

      if (this.viewingGroup) {
        this.viewingGroup = this.groups[this.viewingGroup.id]
        if (this.viewingGroup) {
          const appointmentGroup = this.listDiv.find(
            `.appointment-group-item[data-appointment-group-id='${this.viewingGroup.id}']`
          )
          appointmentGroup.addClass('active')
          appointmentGroup.find('h3 .view_calendar_link').focus()
          this.calendar.displayAppointmentEvents = this.viewingGroup
        } else {
          this.toggleListMode(true)
        }
      }
    }

    $.publish('Calendar/refetchEvents')
    if (this.viewingGroup) {
      return this.calendar.showSchedulerSingle(this.viewingGroup)
    }
  }

  viewCalendarLinkClick = jsEvent => {
    jsEvent.preventDefault()
    if (!this.viewingGroup) {
      $.screenReaderFlashMessageExclusive(I18n.t('Scheduler shown'))
    }
    return this.viewCalendarForElement($(jsEvent.target))
  }

  showEventLinkClick = jsEvent => {
    if (!this.viewingGroup) {
      $.screenReaderFlashMessageExclusive(I18n.t('Scheduler shown'))
    }
    jsEvent.preventDefault()
    const group = this.viewCalendarForElement($(jsEvent.target))

    const eventId = $(jsEvent.target).data('event-id')
    if (eventId) {
      const eventToGoTo = group.object.appointmentEvents.find(appointmentEvent =>
        appointmentEvent.object.childEvents.find(childEvent => childEvent.id === eventId)
      )
      if (eventToGoTo) this.calendar.gotoDate(eventToGoTo.start)
    }
  }

  viewCalendarForElement = el => {
    const thisItem = el.closest('.appointment-group-item')
    const groupId = thisItem.data('appointment-group-id')
    thisItem.addClass('active')
    const group = this.groups && this.groups[groupId]
    this.viewCalendarForGroup(group)
    return group
  }

  viewCalendarForGroupId = id => {
    this.loadData()
    return this.loadingDeferred.done(() =>
      this.viewCalendarForGroup(this.groups && this.groups[id])
    )
  }

  viewCalendarForGroup = group => {
    this.calendar.updateFragment({appointment_group_id: group.id})
    this.toggleListMode(false)
    this.viewingGroup = group

    return this.loadingDeferred.done(() => {
      this.div.addClass('showing-single')

      if (this.viewingGroup.start_at) {
        this.calendar.gotoDate(fcUtil.wrap(this.viewingGroup.start_at))
      } else {
        this.calendar.gotoDate(fcUtil.now())
      }

      this.calendar.displayAppointmentEvents = this.viewingGroup
      $.publish('Calendar/refetchEvents')
      return this.redraw()
    })
  }

  doneClick = jsEvent => {
    if (jsEvent) jsEvent.preventDefault()
    this.toggleListMode(true)
  }

  showList = () => {
    this.div.removeClass('showing-single')
    const target = this.listDiv.find('.appointment-group-item.active h3 .view_calendar_link')
    this.listDiv.find('.appointment-group-item').removeClass('active')

    this.calendar.hideAgendaView()
    this.calendar.displayAppointmentEvents = null
    target.focus()
  }

  editLinkClick = jsEvent => {
    jsEvent.preventDefault()
    let group =
      this.groups &&
      this.groups[
        $(jsEvent.target)
          .closest('.appointment-group-item')
          .data('appointment-group-id')
      ]
    if (!group) return

    this.calendar.dataSource.getEventsForAppointmentGroup(group, events => {
      this.loadData()
      return this.loadingDeferred.done(() => {
        group = this.groups[group.id]
        this.createDialog = new EditAppointmentGroupDialog(
          group,
          this.appointmentGroupContexts,
          this.dialogCloseCB
        )
        this.createDialog.show()
      })
    })
  }

  deleteLinkClick = jsEvent => {
    jsEvent.preventDefault()
    const group =
      this.groups &&
      this.groups[
        $(jsEvent.target)
          .closest('.appointment-group-item')
          .data('appointment-group-id')
      ]
    if (!group) return

    return $('<div />').confirmDelete({
      url: group.url,
      message: $(
        deleteItemTemplate({
          message: I18n.t(
            'confirm_appointment_group_deletion',
            'Are you sure you want to delete this appointment group?'
          ),
          details: I18n.t(
            'appointment_group_deletion_details',
            'Deleting it will also delete any appointments that have been signed up for by students.'
          )
        })
      ),
      dialog: {title: I18n.t('confirm_deletion', 'Confirm Deletion')},
      prepareData: $dialog => ({cancel_reason: $dialog.find('#cancel_reason').val()}),
      confirmed: () =>
        $(jsEvent.target)
          .closest('.appointment-group-item')
          .addClass('event_pending'),
      success: () => {
        this.calendar.dataSource.clearCache()
        this.loadData()
      }
    })
  }

  messageLinkClick = jsEvent => {
    jsEvent.preventDefault()
    const group =
      this.groups &&
      this.groups[
        $(jsEvent.target)
          .closest('.appointment-group-item')
          .data('appointment-group-id')
      ]
    this.messageDialog = new MessageParticipantsDialog({
      group,
      dataSource: this.calendar.dataSource
    })
    return this.messageDialog.show()
  }
}
