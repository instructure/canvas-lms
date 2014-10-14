define [
  'i18n!calendar'
  'jquery'
  'jquery.ajaxJSON'
  'vendor/jquery.ba-tinypubsub'
], (I18n, $) ->

  class
    readableTypes:
      assignment: I18n.t('event_type.assignment', 'Assignment')
      discussion: I18n.t('event_type.discussion', 'Discussion')
      event: I18n.t('event_type.event', 'Event')
      quiz: I18n.t('event_type.quiz', 'Quiz')

    constructor: (data, contextInfo, actualContextInfo) ->
      @eventType = 'generic'
      @contextInfo = contextInfo
      @actualContextInfo = actualContextInfo
      @allPossibleContexts = null
      @className = []
      @object = {}

      @copyDataFromObject(data)

    isNewEvent: () =>
      @eventType == 'generic' || !@object?.id

    isAppointmentGroupFilledEvent: () =>
      @object?.child_events?.length > 0

    isAppointmentGroupEvent: () =>
      @object?.appointment_group_url

    contextCode: () =>
      @object?.effective_context_code || @object?.context_code || @contextInfo?.asset_string

    isUndated: () =>
      @start == null

    isCompleted: -> false

    displayTimeString: () -> ""
    readableType: () -> ""

    fullDetailsURL: () -> null

    startDate: () -> @originalStart || @date
    endDate: () -> @startDate()

    possibleContexts: () -> @allPossibleContexts || [ @contextInfo ]

    addClass: (newClass) =>
      found = false
      for c in @className
        if c == newClass
          found = true
          break
      if !found then @className.push newClass

    removeClass: (rmClass) =>
      idx = 0
      for c in @className
        if c == rmClass
          @className.splice(idx, 1)
        else
          idx += 1

    save: (params, success, error) =>
      onSuccess = (data) =>
        @copyDataFromObject(data)
        $.publish "CommonEvent/eventSaved", this
        success?()

      onError = (data) =>
        $.publish "CommonEvent/eventSaveFailed", this
        error?()

      [ method, url ] = @methodAndURLForSave()

      @forceMinimumDuration() # so short events don't look squished while waiting for ajax
      $.publish "CommonEvent/eventSaving", this
      $.ajaxJSON url, method, params, onSuccess, onError

    isDueAtMidnight: () ->
      @start && (@midnightFudged || (@start.getHours() == 23 && @start.getMinutes() > 30))

    isPast: () ->
      now = $.fudgeDateForProfileTimezone(new Date)
      @start && @start < now

    copyDataFromObject: (data) ->
      @originalStart = (new Date(@start) if @start)
      @midnightFudged = false # clear out cached value because now we have new data
      if @isDueAtMidnight()
        @midnightFudged = true
        @start.setMinutes(30)
        @start.setSeconds(0)
        @end = new Date(@start.getTime()) unless @end
      @forceMinimumDuration()

    forceMinimumDuration: () ->
      minimumDuration = 30 * 60 * 1000 # 30 minutes
      if @start && @end && (@end.getTime() - @start.getTime()) < minimumDuration
        # new date so we don't mutate the original
        @end = new Date(@start.getTime() + minimumDuration)

    assignmentType: () ->
      return if !@assignment
      if @assignment.submission_types?.length
        type = @assignment.submission_types[0]
        if type == 'online_quiz'
          return 'quiz'
        if type == 'discussion_topic'
          return 'discussion'
      return 'assignment'

    iconType: ->
      if type = @assignmentType() then type else 'calendar-month'
