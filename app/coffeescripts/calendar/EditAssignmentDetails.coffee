define [
  'jquery'
  'timezone'
  'compiled/util/fcUtil'
  'compiled/util/natcompare'
  'compiled/calendar/commonEventFactory'
  'jst/calendar/editAssignment'
  'jst/calendar/editAssignmentOverride'
  'jst/calendar/genericSelectOptions'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'jquery.instructure_misc_helpers'
], ($, tz, fcUtil, natcompare, commonEventFactory, editAssignmentTemplate, editAssignmentOverrideTemplate, genericSelectOptionsTemplate) ->

  class EditAssignmentDetails
    constructor: (selector, @event, @contextChangeCB, @closeCB) ->
      @currentContextInfo = null
      tpl = if @event.override then editAssignmentOverrideTemplate else editAssignmentTemplate
      @$form = $(tpl({
        title: @event.title
        contexts: @event.possibleContexts()
      }))
      $(selector).append @$form

      @setupTimeAndDatePickers()

      @$form.submit @formSubmit
      @$form.find(".more_options_link").click @moreOptionsClick
      @$form.find("select.context_id").change @contextChange
      @$form.find("select.context_id").triggerHandler('change', false)

      # Hide the context selector completely if this is an existing event, since it can't be changed.
      if !@event.isNewEvent()
        @$form.find(".context_select").hide()
        @$form.attr('method', 'PUT')
        @$form.attr('action', $.replaceTags(@event.contextInfo.assignment_url, 'id', @event.object.id))

    contextInfoForCode: (code) ->
      for context in @event.possibleContexts()
        if context.asset_string == code
          return context
      return null

    activate: () =>
      @$form.find("select.context_id").change()
      if @event.assignment?.assignment_group_id
        @$form.find(".assignment_group_select .assignment_group").val(@event.assignment.assignment_group_id)

    moreOptionsClick: (jsEvent) =>
      jsEvent.preventDefault()
      pieces = $(jsEvent.target).attr('href').split("#")
      data = @$form.getFormData( object_name: 'assignment' )
      params = {}
      if data.title then params['title'] = data.title
      if data.due_at and @$form.find(".datetime_field").data('unfudged-date')
          params['due_at'] = @$form.find(".datetime_field").data('unfudged-date').toISOString()

      if data.assignment_group_id then params['assignment_group_id'] = data.assignment_group_id
      params['return_to'] = window.location.href
      pieces[0] += "?" + $.param(params)
      window.location.href = pieces.join("#")

    setContext: (newContext) =>
      @$form.find("select.context_id").val(newContext).triggerHandler('change', false)

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
        collection: @currentContextInfo.assignment_groups.sort(natcompare.byKey('name'))
      @$form.find(".assignment_group").html(genericSelectOptionsTemplate(assignmentGroupsSelectOptionsInfo))

      # Update the edit and more options links with the new context
      @$form.attr('action', @currentContextInfo.create_assignment_url)
      moreOptionsUrl = if @event.assignment
                           "#{@event.assignment.html_url}/edit"
                         else
                           @currentContextInfo.new_assignment_url
      @$form.find(".more_options_link").attr('href', moreOptionsUrl)

    setupTimeAndDatePickers: () =>
      $field = @$form.find(".datetime_field")
      $field.datetime_field()
      widget = $field.data('instance')
      startDate = fcUtil.unwrap(@event.startDate())
      if @event.allDay
        widget.setDate(startDate)
      else if startDate
        widget.setDatetime(startDate)

    formSubmit: (e) =>
      e.preventDefault()
      form = @$form.getFormData()
      if form['assignment[due_at]']? then @submitAssignment(form) else @submitOverride(form)

    submitAssignment: (form) ->
      $due_at = @$form.find("#assignment_due_at")

      params = {
        'assignment[name]': @$form.find("#assignment_title").val()
        'assignment[published]': @$form.find("#assignment_published").val() if @$form.find("#assignment_published").is(':checked')
        'assignment[due_at]': $due_at.data('iso8601')
        'assignment[assignment_group_id]': @$form.find(".assignment_group").val()
      }

      if @event.isNewEvent()
        objectData =
          assignment:
            title: params['assignment[name]']
            due_at: params['assignment[due_at]']
            context_code: @$form.find(".context_id").val()
        newEvent = commonEventFactory(objectData, @event.possibleContexts())
        newEvent.save(params)
      else
        @event.title = params['assignment[name]']
        @event.start = $due_at.data('date') # fudged
        @event.save(params)

      @closeCB()

    submitOverride: (form) ->
      $due_at = @$form.find('#assignment_override_due_at')
      params = 'assignment_override[due_at]': $due_at.data('iso8601')
      @event.start = $due_at.data('date') # fudged
      @event.save(params)
      @closeCB()
