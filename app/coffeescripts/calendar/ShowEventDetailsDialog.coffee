define [
  'jquery'
  'i18n!calendar'
  'compiled/util/Popover'
  'compiled/calendar/CommonEvent'
  'compiled/calendar/EditEventDetailsDialog'
  'jst/calendar/eventDetails'
  'jst/calendar/deleteItem'
  'jst/calendar/reservationOverLimitDialog'
  'jquery.ajaxJSON'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
], ($, I18n, Popover, CommonEvent, EditEventDetailsDialog, eventDetailsTemplate, deleteItemTemplate, reservationOverLimitDialog) ->

  class ShowEventDetailsDialog
    constructor: (event) ->
      @event = event
      @contexts = event.contexts

    showEditDialog:() =>
      @popover.hide()
      (new EditEventDetailsDialog(@event)).show()

    deleteEvent: (event) =>
      event ?= @event

      return if @event.isNewEvent()

      url = event.object.url
      # We can't delete assignments via the synthetic calendar_event
      if event.object.assignment
        url = $.replaceTags(@event.deleteURL, 'id', @event.object.id)

      $("<div />").confirmDelete
        url: url
        message: $ deleteItemTemplate(message: event.deleteConfirmation, hide_reason: event.object.workflow_state isnt 'locked')
        dialog: {title: I18n.t('confirm_deletion', "Confirm Deletion")}
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
                       text: I18n.t 'reschedule', 'Reschedule'
                       'class': 'ui-button-primary'
                       click: =>
                         $dialog.disableWhileLoading @reserveEvent({cancel_existing:true}).always ->
                           $dialog.dialog('close')
                     ,
                       text: I18n.t 'do_nothing', 'Do Nothing'
                       click: -> $dialog.dialog('close')
                     ]
                   else
                     [
                       text: I18n.t 'ok', 'OK'
                       click: -> $dialog.dialog('close')
                     ]

      unless errorHandled
        alert "Could not reserve event: #{data}"
        $.publish "CommonEvent/eventSaveFailed", @event

    reserveSuccessCB: (data) =>
      @popover.hide()
      # On success, this will return the new event created for the user.
      $.publish "CommonEvent/eventSaved", @event

    reserveEvent: (params={}) =>
      $.publish "CommonEvent/eventSaving", @event
      $.ajaxJSON @event.object.reserve_url, 'POST', params, @reserveSuccessCB, @reserveErrorCB

    unreserveEvent: () =>
      for e in @event.childEvents
        if e.object?.own_reservation
          @deleteEvent(e)
          return

    show: (jsEvent) =>
      params = $.extend true, {}, @event,
        can_reserve: @event.object?.reserve_url
      # For now, assume that if someone has the ability to create appointment groups
      # in a course, they shouldn't also be able to sign up for them.
      if @event.contextInfo.can_create_appointment_groups
        params.can_reserve = false

      if @event.object?.child_events
        if @event.object.reserved
          params.can_unreserve = true
          params.can_reserve = false

        for e in @event.object.child_events
          if e.user
            (params.reserved_users ?= []).push
              id: e.user.id
              name: e.user.short_name
          if e.group
            (params.reserved_groups ?= []).push
              id: e.group.id
              name: e.group.name

      if @event.object?.available_slots == 0
        params.can_reserve = false
        params.availableSlotsText = "None"
      else if @event.object?.available_slots > 0
        params.availableSlotsText = @event.object.available_slots

      @popover = new Popover(jsEvent, eventDetailsTemplate(params))

      @popover.el.find(".edit_event_link").click (e) =>
        e.preventDefault()
        @showEditDialog()

      @popover.el.find(".delete_event_link").click (e) =>
        e.preventDefault()
        @deleteEvent()

      @popover.el.find(".reserve_event_link").click (e) =>
        e.preventDefault()
        @reserveEvent()

      @popover.el.find(".unreserve_event_link").click (e) =>
        e.preventDefault()
        @unreserveEvent()

      # @popover.dialog 'option',
      #   width: if @event.description?.length > 2000 then Math.max($(window).width() - 300, 450) else 450
