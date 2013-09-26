define [
  'i18n!calendar'
  'jquery'
  'compiled/calendar/CommonEvent'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
], (I18n, $, CommonEvent) ->

  deleteConfirmation = I18n.t('prompts.delete_override', 'Are you sure you want to delete this assignment override?')

  class AssignmentOverride extends CommonEvent
    constructor: (data, contextInfo) ->
      super
      @eventType          = 'assignment_override'
      @deleteConfirmation = deleteConfirmation
      @deleteUrl          = contextInfo.assignment_url
      @addClass 'assignment_override'

    copyDataFromObject: (data) =>
      if data.assignment?
        @copyDataFromAssignment(data.assignment)
        @copyDataFromOverride(data.assignment_override)
      else
        @copyDataFromOverride(data)

      @title  = "#{@assignment.name} (#{@override.title})"
      @object = @override
      @addClass("group_#{@contextCode()}")
      super

    copyDataFromAssignment: (assignment) ->
      @assignment = assignment
      @lock_explanation = @assignment.lock_explanation
      @description = @assignment.description
      @start = @parseStartDate()
      @end = null # in case it got set by midnight fudging

    copyDataFromOverride: (override) ->
      @override = override
      @id = "override_#{@override.id}"
      @assignment.due_at = @override.due_at

    fullDetailsURL: () ->
      @assignment.html_url

    parseStartDate: () ->
      if @assignment.due_at then $.parseFromISO(@assignment.due_at).time else null

    displayTimeString: () ->
      unless datetime = @originalStart
        return "No Date" # TODO: i18n

      # TODO: i18n
      datetime = $.unfudgeDateForProfileTimezone(datetime)
      "Due: <time datetime='#{datetime.toISOString()}'>#{$.datetimeString(datetime)}</time>"

    readableType: () ->
      @readableTypes[@assignmentType()]

    updateAssignmentTitle: (title) ->
      @assignment.title = title
      titleContext = @title.match(/\(.+\)$/)[0]
      @title = "#{title} #{titleContext}"

    saveDates: (success, error) =>
      @save { 'assignment_override[due_at]': $.unfudgeDateForProfileTimezone(@start).toISOString() }, success, error

    methodAndURLForSave: () ->
      url = $.replaceTags(@contextInfo.assignment_override_url,
        assignment_id: @assignment.id,
        id: @override.id)
      ['PUT', url]
