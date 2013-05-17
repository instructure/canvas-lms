define [
  'i18n!calendar'
  'compiled/calendar/CommonEvent'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
], (I18n, CommonEvent) ->

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
      @originalStartDate = new Date(@start) if @start

    copyDataFromOverride: (override) ->
      @override = override
      @id = "override_#{@override.id}"
      @assignment.due_at = @override.due_at

    fullDetailsURL: () ->
      @assignment.html_url

    startDate: () -> @originalStartDate

    parseStartDate: () ->
      if @assignment.due_at then $.parseFromISO(@assignment.due_at, 'due_date').time else null

    displayTimeString: () ->
      if !@start
        return "No Date" # TODO: i18n

      date = @start
      # TODO: i18n
      time_string = "#{$.dateString(date)} at #{$.timeString(date)}"
      "Due: <time datetime='#{date.toISOString()}'>#{time_string}</time>"

    updateAssignmentTitle: (title) ->
      @assignment.title = title
      titleContext = @title.match(/\(.+\)$/)[0]
      @title = "#{title} #{titleContext}"

    saveDates: (success, error) =>
      @save { 'assignment_override[due_at]': $.dateToISO8601UTC($.unfudgeDateForProfileTimezone(@start)) }, success, error

    methodAndURLForSave: () ->
      url = $.replaceTags(@contextInfo.assignment_override_url,
        assignment_id: @assignment.id,
        id: @override.id)
      ['PUT', url]
