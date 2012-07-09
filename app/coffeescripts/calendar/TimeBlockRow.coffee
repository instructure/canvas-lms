define [
  'i18n!calendar'
  'jst/calendar/TimeBlockRow'
], (I18n, timeBlockRowTemplate) ->

  class TimeBlockRow
    constructor: (@TimeBlockList, data={}) ->
      @locked = data.locked
      timeoutId = null
      @$row = $(timeBlockRowTemplate(data)).bind
        focusin: =>
          clearTimeout timeoutId
          @focus()
        focusout: => timeoutId = setTimeout((=> @$row.removeClass('focused')), 50)
      @inputs = {}
      unless @locked
        @$row.find('.date_field').date_field()
        @$row.find('.time_field').time_field()
      $.each @inputNames, (i, inputName) =>
        @inputs[inputName] = {}
        @inputs[inputName].$el = @$row.find("input[name='#{inputName}']").change =>
          @handleInputChange(inputName)
        @updateModel(inputName)
        @inputs[inputName].valid = true if @locked
      @$row.find('.delete-block-link').click(@remove)

    inputNames: ['date', 'start_time', 'end_time']

    updateModel: (inputName) ->
      @inputs[inputName].val = $.trim(@inputs[inputName].$el.val())

    handleInputChange: (inputName) ->
      @updateModel(inputName)
      @validateField(inputName)
      @validate()
      return

    updateDom: (inputName, val) ->
      @inputs[inputName].val = val
      @inputs[inputName].$el.val(val)

    remove: (event) =>
      event?.preventDefault()
      @$row.remove()
      # tell the list that I was removed
      @TimeBlockList.rowRemoved(this)

    focus: =>
      @$row.addClass('focused')
      # scroll all the way down if it is the last row
      # (so the datetime suggest shows up in scrollable area)
      if @$row.is ':last-child'
        @$row.parents('.time-block-list-body-wrapper').scrollTop(9999)

    validateField: (inputName) ->
      $suggest = @inputs[inputName].$el.nextAll('.datetime_suggest')
      invalidDate = $suggest.hasClass('invalid_datetime')
      @updateDom(inputName, $suggest.text()) unless invalidDate
      @inputs[inputName].$el.toggleClass 'error', invalidDate
      @inputs[inputName].valid = !invalidDate

    validate: ->
      return true if @locked
      valid = true
      for own name, input of @inputs
        input.$el.data('associated_error_box')?.remove()
        valid = false unless @validateField(name)
      if valid && !@blank()
        if @validDate() && @inputs.end_time.val && @endAt() < new Date()
          valid = false
          @inputs.end_time.$el
            .addClass('error')
            .errorBox(I18n.t 'ends_in_past_error', 'You cannot create an appointment slot that ends in the past')
        # make sure start is before end
        if @inputs.start_time.val && @inputs.end_time.val
          testDate = @validDate() || 'Today'
          if @timeToDate(testDate, @inputs.end_time.val) <= @timeToDate(testDate, @inputs.start_time.val)
            valid = false
            @inputs.start_time.$el
              .addClass('error')
              .errorBox(I18n.t 'end_before_start_error', 'Start time must be before end time')
      @blank() || valid

    timeToDate: (date, time) ->
      Date.parse date+' '+time

    endAt: ->
      @timeToDate(@inputs.date.val, @inputs.end_time.val) if @validDate()

    startAt: ->
      @timeToDate(@inputs.date.val, @inputs.start_time.val) if @validDate()

    validDate: ->
      @inputs.date.val if @inputs.date.val && @inputs.date.valid

    getData: ->
      [@startAt(), @endAt(), !!@locked]

    blank: ->
      @inputs.date.val is '' and @inputs.start_time.val is '' and @inputs.end_time.val is ''
