define [
  'jquery'
  'compiled/calendar/commonEventFactory'
  'jst/calendar/editAssignment'
  'jst/calendar/editAssignmentOverride'
  'jst/calendar/genericSelectOptions'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'jquery.instructure_misc_helpers'
], ($, commonEventFactory, editAssignmentTemplate, editAssignmentOverrideTemplate, genericSelectOptionsTemplate) ->

  class EditAssignmentDetails
    constructor: (selector, @event, @contextChangeCB, @closeCB) ->
      @currentContextInfo = null
      tpl = if @event.override then editAssignmentOverrideTemplate else editAssignmentTemplate
      @form = $(tpl({
        title: @event.title
        contexts: @event.possibleContexts()
      }))
      $(selector).append @form

      @setupTimeAndDatePickers()

      @form.submit @formSubmit
      @form.find(".more_options_link").click @moreOptionsClick
      @form.find("select.context_id").change @contextChange
      @form.find("select.context_id").triggerHandler('change', false)

      # Hide the context selector completely if this is an existing event, since it can't be changed.
      if !@event.isNewEvent()
        @form.find(".context_select").hide()
        @form.attr('method', 'PUT')
        @form.attr('action', $.replaceTags(@event.contextInfo.assignment_url, 'id', @event.object.id))

    contextInfoForCode: (code) ->
      for context in @event.possibleContexts()
        if context.asset_string == code
          return context
      return null

    activate: () =>
      @form.find("select.context_id").change()
      if @event.assignment?.assignment_group_id
        @form.find(".assignment_group_select .assignment_group").val(@event.assignment.assignment_group_id)

    moreOptionsClick: (jsEvent) =>
      jsEvent.preventDefault()
      pieces = $(jsEvent.target).attr('href').split("#")
      data = @form.getFormData( object_name: 'assignment' )
      params = {}
      if data.title then params['title'] = data.title
      if data.due_at then params['due_at'] = data.due_at
      if data.assignment_group_id then params['assignment_group_id'] = data.assignment_group_id
      params['return_to'] = window.location.href
      pieces[0] += "?" + $.param(params)
      window.location.href = pieces.join("#")

    setContext: (newContext) =>
      @form.find("select.context_id").val(newContext).triggerHandler('change', false)

    contextChange: (jsEvent, propagate) =>
      return if @ignoreContextChange

      context = $(jsEvent.target).val()
      @currentContextInfo = @contextInfoForCode(context)
      @event.contextInfo = @currentContextInfo
      if @currentContextInfo == null then return

      if propagate != false
        @contextChangeCB(context)

      # TODO: support adding a new assignment group from this select box
      assignmentGroupsSelectOptionsInfo =
        collection: @currentContextInfo.assignment_groups
      @form.find(".assignment_group").html(genericSelectOptionsTemplate(assignmentGroupsSelectOptionsInfo))

      # Update the edit and more options links with the new context
      @form.attr('action', @currentContextInfo.create_assignment_url)
      moreOptionsUrl = if @event.assignment
                           "#{@event.assignment.html_url}/edit"
                         else
                           @currentContextInfo.new_assignment_url
      @form.find(".more_options_link").attr('href', moreOptionsUrl)

    setupTimeAndDatePickers: () =>
      @form.find(".datetime_field").datetime_field()

      startDate = @event.startDate()
      endDate = @event.endDate()

      if @event.allDay
        @form.find(".datetime_field").val(startDate.toString('MMM d, yyyy')).change()
      else if startDate
        @form.find(".datetime_field").val(startDate.toString('MMM d, yyyy h:mmtt')).change()

    formSubmit: (e) =>
      e.preventDefault()
      form = @form.getFormData()
      if form['assignment[due_at]']? then @submitAssignment(form) else @submitOverride(form)

    submitAssignment: (form) ->
      dueAtString = form['assignment[due_at]']

      if dueAtString == ''
        dueAt = null
      else
        dueAt = @form.find("#assignment_due_at").data('date')
      params = {
        'assignment[name]': @form.find("#assignment_title").val()
        'assignment[due_at]': if dueAt then $.unfudgeDateForProfileTimezone(dueAt).toISOString() else ''
        'assignment[assignment_group_id]': @form.find(".assignment_group").val()
      }

      if @event.isNewEvent()
        objectData =
          assignment:
            title: params['assignment[name]']
            due_at: if dueAt then dueAt.toISOString() else null
            context_code: @form.find(".context_id").val()
        newEvent = commonEventFactory(objectData, @event.possibleContexts())
        newEvent.save(params)
      else
        @event.title = params['assignment[name]']
        @event.start = dueAt
        @event.save(params)

      @closeCB()

    submitOverride: (form) ->
      dueAt  = form['assignment_override[due_at]']
      dueAt  = if dueAt is '' then null else @form.find('#assignment_override_due_at').data('date')
      params = 'assignment_override[due_at]': if dueAt then $.unfudgeDateForProfileTimezone(dueAt).toISOString() else ''
      @event.start = dueAt
      @event.save(params)
      @closeCB()

