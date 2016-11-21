define [
  'i18n!appt_calendar_event_dialog'
  'jquery'
  'jst/calendar/editApptCalendarEvent'
], (I18n, $, editApptCalendarEventTemplate) ->

  class EditApptCalendarEventDialog
    constructor: (@event) ->
      @form = $('<div></div>')
               .html(editApptCalendarEventTemplate(@event))
               .appendTo('body')

      $maxParticipantsOption = @form.find('[type=checkbox][name=max_participants_option]')
      @$maxParticipants      = @form.find('[name=max_participants]')

      $maxParticipantsOption.change =>
        @$maxParticipants.prop('disabled', not $maxParticipantsOption.prop('checked'))

      if @event.calendarEvent.participants_per_appointment
        $maxParticipantsOption.click()
        @$maxParticipants.val(@event.calendarEvent.participants_per_appointment)

      @dialog = @form.dialog
        autoOpen: false
        width: 'auto'
        resizable: false
        title: I18n.t('title', 'Edit %{name}', name: @event.title)
        buttons: [
          {
            text: I18n.t 'update', 'Update'
            click: @save
          }
        ]
      @dialog.submit (event) =>
        event.preventDefault()
        @save()

    show: -> @dialog.dialog('open')

    save: =>
      formData = @dialog.getFormData()

      limit_participants = formData.max_participants_option == "1"
      max_participants = formData.max_participants

      if limit_participants and max_participants <= 0
        @$maxParticipants.errorBox(I18n.t 'invalid_participants', 'You must allow at least one user to attend')
        return false

      @event.calendarEvent.description = formData.description
      if limit_participants
        @event.calendarEvent.total_slots = max_participants
        @event.calendarEvent.remaining_slots = max_participants - @event.calendarEvent.child_events.length
      else
        @event.calendarEvent.total_slots = undefined
        @event.calendarEvent.remaining_slots = undefined

      participants_per_appointment = if limit_participants then max_participants else ""
      @event.save
        'calendar_event[description]': formData.description
        'calendar_event[participants_per_appointment]': participants_per_appointment

      @dialog.dialog('destroy')
      @form.remove()
