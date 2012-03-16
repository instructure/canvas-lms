define [
  'i18n!appt_calendar_event_dialog'
  'jst/calendar/editApptCalendarEvent'
], (I18n, editApptCalendarEventTemplate) ->

  class EditApptCalendarEventDialog
    constructor: (@event) ->
      form = $('<div></div>')
               .html(editApptCalendarEventTemplate(@event))
               .appendTo('body')

      @dialog = form.dialog
        autoOpen: false
        width: 'auto'
        resizable: false
        title: I18n.t('title', 'Edit %{name}', name: @event.title)
        buttons: [
          {
            text: I18n.t 'update', 'Update'
            class: "button"
            click: @save
          }
        ]

    show: ->
      @dialog.html editApptCalendarEventTemplate(@event)
      @dialog.dialog('open')

    save: =>
      debugger
      description = @dialog.getFormData().description
      @event.calendarEvent.description = description
      @event.save 'calendar_event[description]': description
      @dialog.dialog('destroy')
