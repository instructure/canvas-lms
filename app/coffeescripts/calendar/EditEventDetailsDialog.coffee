define [
  'jquery'
  'i18n!calendar'
  'use!underscore'
  'compiled/calendar/CommonEvent'
  'compiled/calendar/EditCalendarEventDetails'
  'compiled/calendar/EditAssignmentDetails'
  'compiled/calendar/EditApptCalendarEventDetails'
  'compiled/calendar/EditAppointmentGroupDetails'
  'jst/calendar/editEvent'
  'jquery.instructure_jquery_patches'
  'jqueryui/tabs'
], ($, I18n, _, CommonEvent, EditCalendarEventDetails, EditAssignmentDetails, EditApptCalendarEventDetails, EditAppointmentGroupDetails, editEventTemplate) ->

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

      # don't need tabs at all for the appt group calendar events
      if @event.isAppointmentGroupEvent()
        tabs.find('.tab_list').hide()
        return

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
        # don't even show the assignments tab if the user doesn't have
        # permission to create them
        can_create_assignments = _.any(@event.allPossibleContexts, (c) -> c.can_create_assignments)
        unless can_create_assignments
          tabs.tabs('remove', 1)

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

        formHolder = dialog.find('#edit_calendar_event_form_holder')
        ## special case: appointment groups
        if @event.isAppointmentGroupEvent()
          @apptGroupEventForm = new EditApptCalendarEventDetails(formHolder, @event, @contextChange, @closeCB)
          formHolder.data('form-widget', @apptGroupEventForm)
        else
          @calendarEventForm = new EditCalendarEventDetails(formHolder, @event, @contextChange, @closeCB)
          formHolder.data('form-widget', @calendarEventForm)

      if @event.isNewEvent() || @event.eventType == 'assignment'
        @assignmentDetailsForm = new EditAssignmentDetails($('#edit_assignment_form_holder'), @event, @contextChange, @closeCB)
        dialog.find("#edit_assignment_form_holder").data('form-widget', @assignmentDetailsForm)

      @setupTabs()

      # TODO: select the tab that should be active

      dialog.dialog('open')
