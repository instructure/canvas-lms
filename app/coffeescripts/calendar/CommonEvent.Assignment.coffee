define [
  'i18n!calendar'
  'jquery'
  'compiled/calendar/CommonEvent'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
], (I18n, $, CommonEvent) ->

  deleteConfirmation = I18n.t('prompts.delete_assignment', "Are you sure you want to delete this assignment?")

  class Assignment extends CommonEvent
    constructor: (data, contextInfo) ->
      super
      @eventType = 'assignment'
      @deleteConfirmation = deleteConfirmation
      @deleteURL = contextInfo.assignment_url
      @addClass 'assignment'

    copyDataFromObject: (data) =>
      data = data.assignment if data.assignment
      @object = @assignment = data
      @id = "assignment_#{data.id}" if data.id
      @title = data.title || data.name  || "Untitled" # due to a discrepancy between the legacy ajax API and the v1 API
      @lock_explanation = @object.lock_explanation
      @addClass "group_#{@contextCode()}"
      @description = data.description
      @start = @parseStartDate()
      @end = null # in case it got set by midnight fudging

      super

    fullDetailsURL: () ->
      @assignment.html_url

    parseStartDate: () ->
      if @assignment.due_at then $.fudgeDateForProfileTimezone(@assignment.due_at) else null

    displayTimeString: () ->
      unless datetime = @originalStart
        return "No Date" # TODO: i18n

      # TODO: i18n
      datetime = $.unfudgeDateForProfileTimezone(datetime)
      "Due: <time datetime='#{datetime.toISOString()}'>#{$.datetimeString(datetime)}</time>"

    readableType: () ->
      @readableTypes[@assignmentType()]

    saveDates: (success, error) =>
      @save { 'assignment[due_at]': if @start then $.unfudgeDateForProfileTimezone(@start).toISOString() else '' }, success, error

    save: (params, success, error) =>
      $.publish('CommonEvent/assignmentSaved', this)
      super(params, success, error)

    methodAndURLForSave: () ->
      if @isNewEvent()
        method = 'POST'
        url = @contextInfo.create_assignment_url
      else
        method = 'PUT'
        url = $.replaceTags(@contextInfo.assignment_url, 'id', @assignment.id)
      [ method, url ]

    isCompleted: ->
      @assignment.user_submitted || (this.isPast() && @assignment.needs_grading_count == 0)
