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
  'str/htmlEscape'
  '../util/Popover'
  '../util/fcUtil'
  '../calendar/CommonEvent'
  '../calendar/commonEventFactory'
  '../calendar/EditEventDetailsDialog'
  'jst/calendar/eventDetails'
  'jst/calendar/deleteItem'
  'jst/calendar/reservationOverLimitDialog'
  '../calendar/MessageParticipantsDialog'
  '../fn/preventDefault'
  'underscore'
  'axios'
  'vendor/jquery.ba-tinypubsub'
  'jquery.ajaxJSON'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
], ($, I18n, htmlEscape, Popover, fcUtil, CommonEvent, commonEventFactory, EditEventDetailsDialog, eventDetailsTemplate, deleteItemTemplate, reservationOverLimitDialog, MessageParticipantsDialog, preventDefault, _, axios, {publish}) ->

  destroyArguments = (fn) => -> fn.apply(this, [])

  class ShowEventDetailsDialog
    constructor: (event, @dataSource) ->
      @event = event
      @contexts = event.contexts

    showEditDialog:() =>
      @popover.hide()
      (new EditEventDetailsDialog(@event)).show()

    deleteEvent: (event, opts={}) =>
      event ?= @event

      return if @event.isNewEvent()

      url = event.object.url
      # We can't delete assignments via the synthetic calendar_event
      if event.assignment
        url = $.replaceTags(@event.deleteURL, 'id', @event.object.id)

      $("<div />").confirmDelete
        url: url
        message: $ deleteItemTemplate(message: opts.message || event.deleteConfirmation, hide_reason: event.object.workflow_state isnt 'locked')
        dialog: {title: opts.dialogTitle || I18n.t("Confirm Deletion")}
        prepareData: ($dialog) => {cancel_reason: $dialog.find('#cancel_reason').val() }
        confirmed: () =>
          @popover.hide()
          $.publish "CommonEvent/eventDeleting", event
        success: () =>
          $.publish "CommonEvent/eventDeleted", event

    reserveErrorCB: (data, request) =>
      $.publish "CommonEvent/eventSaveFailed", @event
      for error in data when error.message is 'participant has met per-participant limit'
        errorHandled = true
        error.past_appointments = _.all error.reservations, (res) ->
          fcUtil.wrap(res.end_at) < fcUtil.now()
        error.reschedulable = error.reservations.length == 1 && !error.past_appointments
        $dialog = $(reservationOverLimitDialog(error)).dialog
          resizable: false
          width: 450
          buttons: if error.reschedulable
                     [
                       text: I18n.t 'Do Nothing'
                       click: -> $dialog.dialog('close')
                     ,
                       text: I18n.t 'Reschedule'
                       'class': 'btn-primary'
                       click: =>
                         $dialog.disableWhileLoading @reserveEvent({cancel_existing:true}).always ->
                           $dialog.dialog('close')
                     ]
                   else
                     [
                       text: I18n.t 'OK'
                       click: -> $dialog.dialog('close')
                     ]
      unless errorHandled
        # defer to the default error dialog
        $.ajaxJSON.unhandledXHRs.push(request);
        $.fn.defaultAjaxError.func.apply($.fn.defaultAjaxError.object, arguments)

    reserveSuccessCB: (cancel_existing, data) ->
      # remove previous signup(s), if applicable (this has already happened on the backend)
      if cancel_existing
        for own k, v of @dataSource.cache.contexts[data.context_code].events
          if v.eventType == 'calendar_event' and
             v.calendarEvent.parent_event_id and
             v.calendarEvent.appointment_group_id == @event.calendarEvent.appointment_group_id
            $.publish "CommonEvent/eventDeleted", v

      # Update the parent event
      @event.calendarEvent.reserved = true
      @event.calendarEvent.available_slots -= 1
      $.publish "CommonEvent/eventSaved", @event

      # Add the newly created child event
      childEvent = commonEventFactory(data, @dataSource.contexts)
      $.publish "CommonEvent/eventSaved", childEvent

    reserveEvent: (params={}) =>
      params['comments'] = $('#appointment-comment').val()
      @popover.hide()
      $.publish "CommonEvent/eventSaving", @event
      $.ajaxJSON @event.object.reserve_url, 'POST', params, @reserveSuccessCB.bind(this, params.cancel_existing), @reserveErrorCB

    unreserveEvent: =>
      if @event.object?.parent_event_id && @event.object?.appointment_group_id
        events = [@event]
      else
        events = @event.childEvents.filter (e) ->
          e.object?.own_reservation

      for e in events
        @deleteEvent(e, dialogTitle: I18n.t("Confirm Reservation Removal"), message: I18n.t("Are you sure you want to delete your reservation to this event?"))
        return

    cancelAppointment: ($appt) =>
      url = $appt.data('url')
      event = _.detect @event.calendarEvent.child_events, (e) -> e.url == url
      $("<div/>").confirmDelete
        url: url
        message: $ deleteItemTemplate(message: I18n.t(
          'Are you sure you want to cancel your appointment with %{name}?'
          name: event.user?.short_name or event.group.name)
        )
        dialog:
          title: I18n.t("Confirm Removal")
          width: '400px'
          resizable: false
        prepareData: ($dialog) => {cancel_reason: $dialog.find('#cancel_reason').val() }
        success: =>
          @event.object.child_events = _(@event.object.child_events).reject (e) ->
            e.url == $appt.data('url')
          $appt.remove()

          # this is a little funky, but we want to remove the parent (time
          # slot) event from the calendar when there are no attendees, *unless*
          # we are in scheduler view
          in_scheduler = $('#scheduler').prop('checked')
          appointments = @event.calendarEvent.child_events
          if not in_scheduler and appointments.length == 0
            $.publish "CommonEvent/eventDeleted", @event
            @popover.hide()

    show: (jsEvent) =>
      params = $.extend true, {}, @event,
        can_reserve: @event.object?.reserve_url
      # For now, assume that if someone has the ability to create appointment groups
      # in a course, they shouldn't also be able to sign up for them.
      if @event.contextInfo.can_create_appointment_groups
        params.can_reserve = false

      if @event.object?.child_events
        if @event.object.reserved || (@event.object.parent_event_id && @event.object.appointment_group_id)
          params.can_unreserve = (@event.endDate() > fcUtil.now())
          params.can_reserve = false

        for e in @event.object.child_events
          reservation =
            id: e.user?.id or e.group.id
            name: e.user?.short_name or e.group.name
            event_url: e.url
            comments: e.comments
          (params.reservations ?= []).push reservation
          if e.user
            (params.reserved_users ?= []).push reservation
          if e.group
            (params.reserved_groups ?= []).push reservation

      if (!params.reservations? || params.reservations == []) && @event.object.parent_event_id?
        axios.get("api/v1/calendar_events/#{@event.object.parent_event_id}/participants")
         .then((response) =>
            if (response.data?)
              $ul = $("<ul>")
              for p in response.data
                $li = $("<li>").text(p.display_name)
                $ul.append($li)
              $("#reservations").append($ul)
            else
              $("#reservations").remove()
         ).catch( -> $("#reservations").remove())


      if @event.object?.available_slots == 0
        params.can_reserve = false
        params.availableSlotsText = "None"
      else if @event.object?.available_slots > 0
        params.availableSlotsText = @event.object.available_slots

      if @event.calendarEvent
        contextCodes = @event.calendarEvent.all_context_codes.split(',')
        params.isGreaterThanOne = contextCodes.length > 1
        params.contextsCount = contextCodes.length - 1
        params.contextsName = @dataSource.contexts.map((context) =>
          if contextCodes.includes(context.asset_string)
            return context.name
          else
            ""
        ).filter((context) => context.length > 0)

      params.use_new_scheduler = ENV.CALENDAR.BETTER_SCHEDULER
      params.is_appointment_group = !!@event.isAppointmentGroupEvent() # this returns the actual url so make it boolean for clarity
      params.reserve_comments = @event.object.reserve_comments ?= @event.object.comments
      params.showEventLink   = params.fullDetailsURL()
      params.showEventLink or= params.isAppointmentGroupEvent()
      params.isPlannerNote = @event.eventType == 'planner_note'
      if params.isPlannerNote
        # when displayed in the template description is first processed by apiUserContent,
        # which shoves the html string into the document, which will execute any <script>
        params.description = htmlEscape(params.description)

      @popover = new Popover(jsEvent, eventDetailsTemplate(params))
      @popover.el.data('showEventDetailsDialog', @)

      @popover.el.find(".view_event_link").click preventDefault @openShowPage

      @popover.el.find(".edit_event_link").click preventDefault @showEditDialog

      @popover.el.find(".delete_event_link").click preventDefault destroyArguments @deleteEvent

      @popover.el.find(".reserve_event_link").click preventDefault destroyArguments @reserveEvent

      @popover.el.find(".unreserve_event_link").click preventDefault @unreserveEvent

      @popover.el.find(".cancel_appointment_link").click preventDefault (e) =>
        $appt = $(e.target).closest('li')
        @cancelAppointment($appt)

      @popover.el.find('.message_students').click preventDefault =>
        new MessageParticipantsDialog(timeslot: @event.calendarEvent).show()

      publish('userContent/change')

    close: =>
      if @popover
        @popover.el.removeData('showEventDetailsDialog')
        @popover.hide()

    openShowPage: (jsEvent) =>
      pieces = $(jsEvent.target).attr('href').split("#")
      pieces[0] += "?" + $.param({'return_to': window.location.href})
      window.location.href = pieces.join("#")
