define [
  'i18n!instructure'
  'jquery'
  'timezone'
  'jquery.instructure_date_and_time' # $.datetime.parse, $.unfudgeDateForProfileTimezone, $.midnight
], (I18n, $, tz) ->

  # adds datepicker and suggest functionality to the specified $field
  class DatetimeField
    datepickerDefaults:
      constrainInput: false
      dateFormat: 'M d, yy'
      showOn: 'button'
      buttonText: '<i class="icon-calendar-month"></i>'
      buttonImageOnly: false

    parseError: I18n.t('errors.not_a_date', "That's not a date!")
    courseLabel: I18n.t('#helpers.course', 'Course') + ": "
    localLabel: I18n.t('#helpers.local', 'Local') + ": "

    constructor: (@$field, options={}) ->
      @$field.data(instance: this)

      @processTimeOptions(options)
      $wrapper = @addDatePicker(options) if @showDate
      @addSuggests($wrapper || @$field, options)
      @addHiddenInput() if options.addHiddenInput

      # when the input changes, update this object from the new value
      @$field.bind "change focus blur keyup", @setFromValue

      # process initial value
      @setFromValue()

    processTimeOptions: (options) ->
      # default undefineds to false
      timeOnly = options.timeOnly
      dateOnly = options.dateOnly
      alwaysShowTime = options.alwaysShowTime

      # as long as options.timeOnly and options.dateOnly aren't both true,
      # showDate || showTime will always be true; i.e. not showDate implies
      # showTime, and vice versa. that's a nice property, so let's enforce it
      # (treating the provision as both as the provision of neither)
      if timeOnly and dateOnly
        console.warn("DatetimeField instantiated with both timeOnly and dateOnly true.")
        console.warn("Treating both as false instead.")
        timeOnly = dateOnly = false

      @showDate = not timeOnly
      @allowTime = not dateOnly
      @alwaysShowTime = @allowTime and (timeOnly or alwaysShowTime)

    addDatePicker: (options) ->
      @$field.wrap('<div class="input-append" />')
      $wrapper = @$field.parent('.input-append')
      datepickerOptions = $.extend {}, @datepickerDefaults, {timePicker: @allowTime}, options.datepicker
      @$field.datepicker(datepickerOptions)

      # TEMPORARY FIX: Hide from aria screenreader until the jQuery UI datepicker is updated for accessibility.
      $datepickerButton = @$field.next()
      $datepickerButton.attr('aria-hidden', 'true')
      $datepickerButton.attr('tabindex', '-1')

      return $wrapper

    addSuggests: ($sibling, options={}) ->
      @courseTimezone = options.courseTimezone or ENV.CONTEXT_TIMEZONE
      @$suggest = $('<div class="datetime_suggest" />').insertAfter($sibling)
      if @courseTimezone? and @courseTimezone isnt ENV.TIMEZONE
        @$courseSuggest = $('<div class="datetime_suggest" />').insertAfter(@$suggest)

    addHiddenInput: ->
      @$hiddenInput = $('<input type="hidden">').insertAfter(@$field)
      @$hiddenInput.attr('name', @$field.attr('name'))
      @$hiddenInput.val(@$field.val())
      @$field.removeAttr('name')
      @$field.data('hiddenInput', @$hiddenInput)

    # public API
    setDate: (date) =>
      @setFormattedDatetime(date, 'MMM d, yyyy')

    setTime: (date) =>
      @setFormattedDatetime(date, 'h:mmtt')

    setDatetime: (date) =>
      @setFormattedDatetime(date, 'MMM d, yyyy h:mmtt')

    # private API
    setFromValue: =>
      @parseValue()
      @update()

    normalizeValue: (value) ->
      return value unless value?

      # trim leading/trailing whitespace
      value = value.trim()
      return value if value is ""

      # for anything except time-only fields, that's all we do
      return value if @showDate

      # and for time-only fields, we only modify if it's one or two digits
      return value unless value.match(/^\d{1,2}$/)

      # if it has a leading zero, it's always 24 hour time
      return "#{value}:00" if value.match(/^0/)

      # otherwise, treat things from 1 and 7 as PM, and from 8 and 23 as
      # 24-hour time. >= 24 are not valid hour specifications (nor < 0, but
      # those were caught above, since we only have digits at this point) and
      # are just returned as is
      parsedValue = parseInt(value, 10)
      if parsedValue < 0 or parsedValue >= 24
        value
      else if parsedValue < 8
        "#{parsedValue}pm"
      else
        "#{parsedValue}:00"

    parseValue: ->
      value = @normalizeValue(@$field.val())
      @fudged = $.datetime.parse(value)
      @datetime = $.unfudgeDateForProfileTimezone(@fudged)
      @showTime = @alwaysShowTime or (@allowTime and not $.midnight(@datetime))
      @blank = not value
      @invalid = not @blank and @datetime == null

    setFormattedDatetime: (datetime, format) ->
      if datetime
        @datetime = datetime
        @fudged = $.fudgeDateForProfileTimezone(@datetime)
        @$field.val(@fudged.toString(format))
      else
        @datetime = null
        @fudged = null
        @$field.val("")
      @blank = @datetime is null
      @invalid = false
      @showTime = @alwaysShowTime or (@allowTime and not $.midnight(@datetime))
      @update()

    update: (updates) ->
      @updateData()
      @updateSuggest()
      @updateAriaAlert()

    updateData: ->
      iso8601 = @datetime?.toISOString() || ''
      @$field.data
        'unfudged-date': @datetime
        'date': @fudged
        'iso8601': iso8601
        'blank': @blank
        'invalid': @invalid

      if @$hiddenInput
        @$hiddenInput.val(@fudged)

      # date_fields and time_fields don't have timepicker data fields
      return unless @showDate and @allowTime
      if @invalid or @blank or not @showTime
        @$field.data
          'time-hour': null
          'time-minute': null
          'time-ampm': null
      else
        @$field.data
          'time-hour': tz.format(@datetime, "%-l")
          'time-minute': tz.format(@datetime, "%M")
          'time-ampm': tz.format(@datetime, "%P")

    updateSuggest: ->
      text = @formatSuggest()
      if @$courseSuggest
        courseText = @formatSuggestCourse()
        if courseText
          text = @localLabel + text
          courseText = @courseLabel + courseText
        @$courseSuggest.text(courseText)
      @$suggest
        .toggleClass('invalid_datetime', @invalid)
        .text(text)

    updateAriaAlert: ->
      if @$field.data('accessible-message-timeout')
        # clear any previously scheduled message; we're about to reschedule
        # iff still needed
        clearTimeout(@$field.data('accessible-message-timeout'))
        @$field.removeData('accessible-message-timeout')
      if @invalid
        # set timeout to speak the parse error via #aria_alerts
        callback = =>
          $('#aria_alerts').text(@parseError)
          @$field.removeData('accessible-message-timeout')
        @$field.data('accessible-message-timeout', setTimeout(callback, 2000))

    formatSuggest: ->
      if @blank
        ""
      else if @invalid
        @parseError
      else if @showDate and @showTime
        tz.format(@datetime, "%a %b %-d, %Y %-l:%M%P")
      else if @showDate
        tz.format(@datetime, "%a %b %-d, %Y")
      else
        tz.format(@datetime, "%-l:%M%P")

    formatSuggestCourse: ->
      if @blank
        ""
      else if @invalid
        ""
      else if @showDate and @showTime
        tz.format(@datetime, "%a %b %-d, %Y %-l:%M%P", @courseTimezone)
      else if @showTime
        tz.format(@datetime, "%-l:%M%P", @courseTimezone)
      else
        ""
