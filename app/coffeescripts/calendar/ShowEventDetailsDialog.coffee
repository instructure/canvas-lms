define [
  'jquery'
  'i18n!calendar'
  'compiled/util/Popover'
  'compiled/calendar/CommonEvent'
  'compiled/calendar/commonEventFactory'
  'compiled/calendar/EditEventDetailsDialog'
  'jst/calendar/eventDetails'
  'jst/calendar/deleteItem'
  'jst/calendar/reservationOverLimitDialog'
  'compiled/calendar/MessageParticipantsDialog'
  'compiled/fn/preventDefault'
  'underscore'
  'vendor/jquery.ba-tinypubsub'
  'jquery.ajaxJSON'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
], ($, I18n, Popover, CommonEvent, commonEventFactory, EditEventDetailsDialog, eventDetailsTemplate, deleteItemTemplate, reservationOverLimitDialog, MessageParticipantsDialog, preventDefault, _, {publish}) ->

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
        dialog: {title: opts.dialogTitle || I18n.t('confirm_deletion', "Confirm Deletion")}
        prepareData: ($dialog) => {cancel_reason: $dialog.find('#cancel_reason').val() }
        confirmed: () =>
          @popover.hide()
          $.publish "CommonEvent/eventDeleting", event
        success: () =>
          $.publish "CommonEvent/eventDeleted", event

    reserveErrorCB: (data) =>
      for error in data when error.message is 'participant has met per-participant limit'
        errorHandled = true
        error.reschedulable = error.reservations.length == 1
        $dialog = $(reservationOverLimitDialog(error)).dialog
          resizable: false
          width: 450
          buttons: if error.reschedulable
                     [
                       text: I18n.t 'do_nothing', 'Do Nothing'
                       click: -> $dialog.dialog('close')
                     ,
                       text: I18n.t 'reschedule', 'Reschedule'
                       'class': 'btn-primary'
                       click: =>
                         $dialog.disableWhileLoading @reserveEvent({cancel_existing:true}).always ->
                           $dialog.dialog('close')
                     ]
                   else
                     [
                       text: I18n.t 'ok', 'OK'
                       click: -> $dialog.dialog('close')
                     ]

      unless errorHandled
        alert "Could not reserve event: #{data}"
        $.publish "CommonEvent/eventSaveFailed", @event

    reserveSuccessCB: (cancel_existing, data) ->
      @popover.hide()

      # remove previous signup(s), if applicable (this has already happened on the backend)
      if cancel_existing
        for own k, v of @dataSource.cache.contexts[@event.contextInfo.asset_string].events
          if v.eventType == 'calendar_event' and
             v.calendarEvent.parent_event_id and
             v.calendarEvent.appointment_group_id == @event.calendarEvent.appointment_group_id
            $.publish "CommonEvent/eventDeleted", v

      # Update the parent event
      @event.calendarEvent.reserved = true
      @event.calendarEvent.available_slots -= 1
      $.publish "CommonEvent/eventSaved", @event

      # Add the newly created child event
      childEvent = commonEventFactory(data, [@event.contextInfo])
      $.publish "CommonEvent/eventSaved", childEvent

    reserveEvent: (params={}) =>
      params['comments'] = $('#appointment-comment').val()
      $.publish "CommonEvent/eventSaving", @event
      $.ajaxJSON @event.object.reserve_url, 'POST', params, @reserveSuccessCB.bind(this, params.cancel_existing), @reserveErrorCB

    unreserveEvent: =>
      if @event.object?.parent_event_id && @event.object?.appointment_group_id
        events = [@event]
      else
        events = @event.childEvents.filter (e) ->
          e.object?.own_reservation

      for e in events
        @deleteEvent(e, dialogTitle: I18n.t('confirm_unreserve', "Confirm Reservation Removal"), message: I18n.t('prompts.unreserve_event', "Are you sure you want to delete your reservation to this event?"))
        return

    cancelAppointment: ($appt) =>
      url = $appt.data('url')
      event = _.detect @event.calendarEvent.child_events, (e) -> e.url == url
      $("<div/>").confirmDelete
        url: url
        message: $ deleteItemTemplate(message: I18n.t(
          'cancel_appointment'
          'Are you sure you want to cancel your appointment with %{name}?'
          name: event.user?.short_name or event.group.name)
        )
        dialog:
          title: I18n.t('confirm_removal', "Confirm Removal")
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
          params.can_unreserve = true
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

      if @event.object?.available_slots == 0
        params.can_reserve = false
        params.availableSlotsText = "None"
      else if @event.object?.available_slots > 0
        params.availableSlotsText = @event.object.available_slots

      params.use_new_scheduler = ENV.CALENDAR.BETTER_SCHEDULER
      params.is_appointment_group = !!@event.isAppointmentGroupEvent() # this returns the actual url so make it boolean for clarity
      params.reserve_comments = @event.object.reserve_comments ?= @event.object.comments
      params.showEventLink   = params.fullDetailsURL()
      params.showEventLink or= params.isAppointmentGroupEvent()
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
