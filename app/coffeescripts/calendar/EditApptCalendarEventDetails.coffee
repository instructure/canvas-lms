define 'compiled/calendar/EditApptCalendarEventDetails', [
  'i18n'
  'jst/calendar/editApptCalendarEvent'
], (I18n, editApptCalendarEventTemplate) ->

  class EditApptCalendarEventDetails
    constructor: (selector, @event, @contextChangeCB, @closeCB) ->
      @form = $( editApptCalendarEventTemplate apptEvent: @event )
      $(selector).append @form
      @form.submit @formSubmit

    formSubmit: (jsEvent) =>
      jsEvent.preventDefault()
      description = @form.getFormData().description

      @event.calendarEvent.description = description
      @event.save 'calendar_event[description]': description

      @closeCB()
