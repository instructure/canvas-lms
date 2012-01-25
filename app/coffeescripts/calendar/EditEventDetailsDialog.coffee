define 'compiled/calendar/EditEventDetailsDialog', [
  'i18n'
  'compiled/calendar/CommonEvent'
  'compiled/calendar/EditCalendarEventDetails'
  'compiled/calendar/EditAssignmentDetails'
  'compiled/calendar/EditAppointmentGroupDetails'
  'jst/calendar/editEvent'
], (I18n, CommonEvent, EditCalendarEventDetails, EditAssignmentDetails, EditAppointmentGroupDetails, editEventTemplate) ->

  I18n = I18n.scoped 'calendar'

  dialog = $('<div id="edit_event"><div /></div>').appendTo('body').dialog
    autoOpen: false
    width: 'auto'
    resizable: false
    title: I18n.t('titles.edit_event', "Edit Event")

  class
    constructor: (@event) ->
      @currentContextInfo = null

    contextInfoForCode: (code) ->
      for context in @event.possibleContexts()
        if context.asset_string == code
          return context
      return null

    setupTabs: =>
      # Set up the tabbed view of the dialog
      tabs = dialog.find("#edit_event_tabs")
      tabs.tabs().bind 'tabsselect', (event, ui) ->
        $(ui.panel).closest(".tab_holder").data('form-widget').activate()

      if @event.eventType == 'calendar_event'
        tabs.tabs('select', 0)
        tabs.tabs('remove', 1)
        @calendarEventForm.activate()
      else if @event.eventType == 'assignment'
        tabs.tabs('select', 1)
        tabs.tabs('remove', 0)
        @assignmentDetailsForm.activate()
      else
        @calendarEventForm.activate()

    contextChange: (newContext) =>
      # Update the style of the dialog box to reflect the current context
      dialog.removeClass dialog.data('group_class')
      dialog.addClass("group_#{newContext}").data('group_class', "group_#{newContext}")
      @calendarEventForm.setContext(newContext) if @calendarEventForm
      @assignmentDetailsForm.setContext(newContext) if @assignmentDetailsForm

    closeCB: () =>
      dialog.dialog('close')

    show: =>
      html = editEventTemplate()
      dialog.children().replaceWith(html)

      if @event.isNewEvent() || @event.eventType == 'calendar_event'
        @calendarEventForm = new EditCalendarEventDetails(dialog.find("#edit_calendar_event_form_holder"), @event, @contextChange, @closeCB)
        dialog.find("#edit_calendar_event_form_holder").data('form-widget', @calendarEventForm)

      if @event.isNewEvent() || @event.eventType == 'assignment'
        @assignmentDetailsForm = new EditAssignmentDetails(dialog.find("#edit_assignment_form_holder"), @event, @contextChange, @closeCB)
        dialog.find("#edit_assignment_form_holder").data('form-widget', @assignmentDetailsForm)

      @setupTabs()

      # TODO: select the tab that should be active

      dialog.dialog('open')
