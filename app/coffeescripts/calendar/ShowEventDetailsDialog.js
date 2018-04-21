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
import htmlEscape from 'str/htmlEscape'
import Popover from '../util/Popover'
import fcUtil from '../util/fcUtil'
import commonEventFactory from '../calendar/commonEventFactory'
import EditEventDetailsDialog from '../calendar/EditEventDetailsDialog'
import eventDetailsTemplate from 'jst/calendar/eventDetails'
import deleteItemTemplate from 'jst/calendar/deleteItem'
import reservationOverLimitDialog from 'jst/calendar/reservationOverLimitDialog'
import MessageParticipantsDialog from '../calendar/MessageParticipantsDialog'
import preventDefault from '../fn/preventDefault'
import _ from 'underscore'
import axios from 'axios'
import {publish} from 'vendor/jquery.ba-tinypubsub'
import 'jquery.ajaxJSON'
import 'jquery.instructure_misc_helpers'
import 'jquery.instructure_misc_plugins'

const destroyArguments = fn =>
  function() {
    return fn.apply(this, [])
  }

export default class ShowEventDetailsDialog {
  constructor(event, dataSource) {
    this.dataSource = dataSource
    this.event = event
    this.contexts = event.contexts
  }

  showEditDialog = () => {
    this.popover.hide()
    new EditEventDetailsDialog(this.event).show()
  }

  deleteEvent = (event, opts = {}) => {
    if (event == null) event = this.event

    if (this.event.isNewEvent()) return

    let {url} = event.object
    // We can't delete assignments via the synthetic calendar_event
    if (event.assignment) {
      url = $.replaceTags(this.event.deleteURL, 'id', this.event.object.id)
    }

    return $('<div />').confirmDelete({
      url,
      message: $(
        deleteItemTemplate({
          message: opts.message || event.deleteConfirmation,
          hide_reason: event.object.workflow_state !== 'locked'
        })
      ),
      dialog: {title: opts.dialogTitle || I18n.t('Confirm Deletion')},
      prepareData: $dialog => ({cancel_reason: $dialog.find('#cancel_reason').val()}),
      confirmed: () => {
        this.popover.hide()
        $.publish('CommonEvent/eventDeleting', event)
      },
      success: () => {
        $.publish('CommonEvent/eventDeleted', event)
      }
    })
  }

  reserveErrorCB = (data, request) => {
    let errorHandled
    $.publish('CommonEvent/eventSaveFailed', this.event)
    data.forEach(error => {
      if (error.message === 'participant has met per-participant limit') {
        errorHandled = true
        error.past_appointments = _.all(
          error.reservations,
          res => fcUtil.wrap(res.end_at) < fcUtil.now()
        )
        error.reschedulable = error.reservations.length === 1 && !error.past_appointments
        const $dialog = $(reservationOverLimitDialog(error)).dialog({
          resizable: false,
          width: 450,
          buttons: error.reschedulable
            ? [
                {
                  text: I18n.t('Do Nothing'),
                  click() {
                    $dialog.dialog('close')
                  }
                },
                {
                  text: I18n.t('Reschedule'),
                  class: 'btn-primary',
                  click: () => {
                    $dialog.disableWhileLoading(
                      this.reserveEvent({cancel_existing: true}).always(() =>
                        $dialog.dialog('close')
                      )
                    )
                  }
                }
              ]
            : [
                {
                  text: I18n.t('OK'),
                  click() {
                    $dialog.dialog('close')
                  }
                }
              ]
        })
      }
    })
    if (!errorHandled) {
      // defer to the default error dialog
      $.ajaxJSON.unhandledXHRs.push(request)
      return $.fn.defaultAjaxError.func.apply($.fn.defaultAjaxError.object, arguments)
    }
  }

  reserveSuccessCB(cancel_existing, data) {
    // remove previous signup(s), if applicable (this has already happened on the backend)
    if (cancel_existing) {
      const ref = this.dataSource.cache.contexts[data.context_code].events
      const results = []
      const hasProp = {}.hasOwnProperty
      for (const k in ref) {
        if (!hasProp.call(ref, k)) continue
        const v = ref[k]
        if (
          v.eventType === 'calendar_event' &&
          v.calendarEvent.parent_event_id &&
          v.calendarEvent.appointment_group_id === this.event.calendarEvent.appointment_group_id
        ) {
          results.push($.publish('CommonEvent/eventDeleted', v))
        } else {
          results.push(void 0)
        }
      }
      return results
    }

    // Update the parent event
    this.event.calendarEvent.reserved = true
    this.event.calendarEvent.available_slots -= 1
    $.publish('CommonEvent/eventSaved', this.event)

    // Add the newly created child event
    const childEvent = commonEventFactory(data, this.dataSource.contexts)
    $.publish('CommonEvent/eventSaved', childEvent)
  }

  reserveEvent = (params = {}) => {
    params.comments = $('#appointment-comment').val()
    this.popover.hide()
    $.publish('CommonEvent/eventSaving', this.event)
    return $.ajaxJSON(
      this.event.object.reserve_url,
      'POST',
      params,
      this.reserveSuccessCB.bind(this, params.cancel_existing),
      this.reserveErrorCB
    )
  }

  unreserveEvent = () => {
    let events
    if (
      this.event.object &&
      this.event.object.parent_event_id &&
      this.event.object.appointment_group_id
    ) {
      events = [this.event]
    } else {
      events = this.event.childEvents.filter(e => e.object && e.object.own_reservation)
    }

    for (let i = 0; i < events.length; i++) {
      const e = events[i]
      this.deleteEvent(e, {
        dialogTitle: I18n.t('Confirm Reservation Removal'),
        message: I18n.t('Are you sure you want to delete your reservation to this event?')
      })
      return
    }
  }

  cancelAppointment = $appt => {
    const url = $appt.data('url')
    const event = _.detect(this.event.calendarEvent.child_events, e => e.url === url)
    $('<div/>').confirmDelete({
      url,
      message: $(
        deleteItemTemplate({
          message: I18n.t('Are you sure you want to cancel your appointment with %{name}?', {
            name: (event.user && event.user.short_name) || event.group.name
          })
        })
      ),
      dialog: {
        title: I18n.t('Confirm Removal'),
        width: '400px',
        resizable: false
      },
      prepareData: $dialog => ({cancel_reason: $dialog.find('#cancel_reason').val()}),
      success: () => {
        this.event.object.child_events = _(this.event.object.child_events).reject(
          e => e.url === $appt.data('url')
        )
        $appt.remove()

        // this is a little funky, but we want to remove the parent (time
        // slot) event from the calendar when there are no attendees, *unless*
        // we are in scheduler view
        const in_scheduler = $('#scheduler').prop('checked')
        const appointments = this.event.calendarEvent.child_events
        if (!in_scheduler && appointments.length === 0) {
          $.publish('CommonEvent/eventDeleted', this.event)
          this.popover.hide()
        }
      }
    })
  }

  show = jsEvent => {
    const params = $.extend(true, {}, this.event, {
      can_reserve: this.event.object && this.event.object.reserve_url
    })
    // For now, assume that if someone has the ability to create appointment groups
    // in a course, they shouldn't also be able to sign up for them.
    if (this.event.contextInfo.can_create_appointment_groups) {
      params.can_reserve = false
    }

    if (this.event.object && this.event.object.child_events) {
      if (
        this.event.object.reserved ||
        (this.event.object.parent_event_id && this.event.object.appointment_group_id)
      ) {
        params.can_unreserve = this.event.endDate() > fcUtil.now()
        params.can_reserve = false
      }

      this.event.object.child_events.forEach(e => {
        const reservation = {
          id: (e.user && e.user.id) || e.group.id,
          name: (e.user && e.user.short_name) || e.group.name,
          event_url: e.url,
          comments: e.comments
        }
        ;(params.reservations ? params.reservations : (params.reservations = [])).push(reservation)
        if (e.user) {
          ;(params.reserved_users ? params.reserved_users : (params.reserved_users = [])).push(
            reservation
          )
        }
        if (e.group) {
          ;(params.reserved_groups ? params.reserved_groups : (params.reserved_groups = [])).push(
            reservation
          )
        }
      })
    }

    if (
      (params.reservations == null || params.reservations === []) &&
      this.event.object.parent_event_id != null
    ) {
      axios
        .get(`api/v1/calendar_events/${this.event.object.parent_event_id}/participants`)
        .then(response => {
          if (response.data) {
            const $ul = $('<ul>')
            response.data.forEach(p => {
              const $li = $('<li>').text(p.display_name)
              $ul.append($li)
            })
            $('#reservations').append($ul)
          } else {
            $('#reservations').remove()
          }
        })
        .catch(() => $('#reservations').remove())
    }

    if ((this.event.object && this.event.object.available_slots) === 0) {
      params.can_reserve = false
      params.availableSlotsText = 'None'
    } else if ((this.event.object && this.event.object.available_slots) > 0) {
      params.availableSlotsText = this.event.object.available_slots
    }

    if (this.event.calendarEvent) {
      const contextCodes = this.event.calendarEvent.all_context_codes.split(',')
      params.isGreaterThanOne = contextCodes.length > 1
      params.contextsCount = contextCodes.length - 1
      params.contextsName = this.dataSource.contexts
        .map(context => {
          if (contextCodes.includes(context.asset_string)) {
            return context.name
          } else {
            return ''
          }
        })
        .filter(context => context.length > 0)
    }

    params.use_new_scheduler = ENV.CALENDAR.BETTER_SCHEDULER
    params.is_appointment_group = !!this.event.isAppointmentGroupEvent() // this returns the actual url so make it boolean for clarity
    params.reserve_comments =
      this.event.object.reserve_comments != null
        ? this.event.object.reserve_comments
        : (this.event.object.reserve_comments = this.event.object.comments)
    params.showEventLink = params.fullDetailsURL()
    if (!params.showEventLink) {
      params.showEventLink = params.isAppointmentGroupEvent()
    }
    params.isPlannerNote = this.event.eventType === 'planner_note'
    if (params.isPlannerNote) {
      // when displayed in the template description is first processed by apiUserContent,
      // which shoves the html string into the document, which will execute any <script>
      params.description = htmlEscape(params.description)
    }

    this.popover = new Popover(jsEvent, eventDetailsTemplate(params))
    this.popover.el.data('showEventDetailsDialog', this)

    this.popover.el.find('.view_event_link').click(preventDefault(this.openShowPage))

    this.popover.el.find('.edit_event_link').click(preventDefault(this.showEditDialog))

    this.popover.el
      .find('.delete_event_link')
      .click(preventDefault(destroyArguments(this.deleteEvent)))

    this.popover.el
      .find('.reserve_event_link')
      .click(preventDefault(destroyArguments(this.reserveEvent)))

    this.popover.el.find('.unreserve_event_link').click(preventDefault(this.unreserveEvent))

    this.popover.el.find('.cancel_appointment_link').click(
      preventDefault(e => {
        const $appt = $(e.target).closest('li')
        this.cancelAppointment($appt)
      })
    )

    this.popover.el.find('.message_students').click(
      preventDefault(() => {
        new MessageParticipantsDialog({timeslot: this.event.calendarEvent}).show()
      })
    )

    publish('userContent/change')
  }

  close = () => {
    if (this.popover) {
      this.popover.el.removeData('showEventDetailsDialog')
      this.popover.hide()
    }
  }

  openShowPage = jsEvent => {
    const pieces = $(jsEvent.target)
      .attr('href')
      .split('#')
    pieces[0] += `?${$.param({return_to: window.location.href})}`
    window.location.href = pieces.join('#')
  }
}
