define [
  'i18n!calendar',
  'compiled/calendar/CommonEvent'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
], (I18n, CommonEvent) ->

  deleteConfirmation = I18n.t('prompts.delete_assignment', "Are you sure you want to delete this assignment?")

  class Assignment extends CommonEvent
    constructor: (data, contextInfo) ->
      super
      @eventType = 'assignment'
      @deleteConfirmation = deleteConfirmation
      @deleteURL = contextInfo.assignment_url
      @addClass 'assignment'

      @copyDataFromObject(data)

    copyDataFromObject: (data) =>
      data = data.assignment if data.assignment
      @object = @assignment = data
      @id = "assignment_#{data.id}"
      @title = data.title || data.name  || "Untitled" # due to a discrepancy between the legacy ajax API and the v1 API
      @lock_explanation = @object.lock_explanation
      @addClass "group_#{@contextCode()}"

      @start = if data.due_at then $.parseFromISO(data.due_at, "due_date").time else null
      if @isDueAtMidnight()
        @midnightFudged = true
        @start.setMinutes(30)

      @description = data.description

    fullDetailsURL: () ->
      $.replaceTags(@contextInfo.assignment_url, 'id', @assignment.id)

    startDate: () ->
      if @assignment.due_at then $.parseFromISO(@assignment.due_at, 'due_date').time else null

    displayTimeString: () ->
      if !@assignment.due_at
        return "No Date" # TODO: i18n

      date = $.parseFromISO @assignment.due_at, 'due_date'
      # TODO: i18n
      time_string = "#{$.dateString(date.date)} at #{date.time_string}"
      "Due: <time datetime='#{date.time.toISOString()}'>#{time_string}</time>"

    saveDates: (success, error) =>
      @save { 'assignment[due_at]': $.dateToISO8601UTC($.unfudgeDateForProfileTimezone(@start)) }, success, error

    methodAndURLForSave: () ->
      if @isNewEvent()
        method = 'POST'
        url = @contextInfo.create_assignment_url
      else
        method = 'PUT'
        url = $.replaceTags(@contextInfo.assignment_url, 'id', @assignment.id)
      [ method, url ]

    isDueAtMidnight: () ->
      @midnightFudged || @start && @start.getHours() == 23 && @start.getMinutes() == 59
