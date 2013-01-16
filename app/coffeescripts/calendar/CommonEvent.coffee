define [
  'jquery'
  'jquery.ajaxJSON'
  'vendor/jquery.ba-tinypubsub'
], ($) ->

  class
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

    displayTimeString: () -> ""
    readableType: () -> ""

    fullDetailsURL: () -> null

    startDate: () -> @date
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

      $.publish "CommonEvent/eventSaving", this
      $.ajaxJSON url, method, params, onSuccess, onError

    isDueAtMidnight: () ->
      @start && (@midnightFudged || (@start.getHours() == 23 && @start.getMinutes() == 59))

    copyDataFromObject: (data) ->
      if @isDueAtMidnight()
        @midnightFudged = true
        @start.setMinutes(30)
