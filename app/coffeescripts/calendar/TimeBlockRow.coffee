define [
  'jquery'
  'i18n!calendar'
  'jst/calendar/TimeBlockRow'
], ($, I18n, timeBlockRowTemplate) ->

  class TimeBlockRow
    constructor: (@TimeBlockList, data={}) ->
      @locked = data.locked
      timeoutId = null
      @$row = $(timeBlockRowTemplate(data)).bind
        focusin: =>
          clearTimeout timeoutId
          @focus()
        focusout: => timeoutId = setTimeout((=> @$row.removeClass('focused')), 50)

      @$date = @$row.find("input[name='date']")
      @$start_time = @$row.find("input[name='start_time']")
      @$end_time = @$row.find("input[name='end_time']")

      @$date.date_field().change(@validate)
      @$start_time.time_field().change(@validate)
      @$end_time.time_field().change(@validate)

      @$row.find('.delete-block-link').click(@remove)

    remove: (event) =>
      event?.preventDefault()
      @$row.remove()
      # tell the list that I was removed
      @TimeBlockList.rowRemoved(this)
      # Send the keyboard focus to a reasonable location.
      $('input.date_field:visible').focus()

    focus: =>
      @$row.addClass('focused')
      # scroll all the way down if it is the last row
      # (so the datetime suggest shows up in scrollable area)
      if @$row.is ':last-child'
        @$row.parents('.time-block-list-body-wrapper').scrollTop(9999)

    validate: =>
      # clear previous errors
      @$date.data('associated_error_box')?.remove()
      @$date.toggleClass 'error', false
      @$start_time.data('associated_error_box')?.remove()
      @$start_time.toggleClass 'error', false
      @$end_time.data('associated_error_box')?.remove()
      @$end_time.toggleClass 'error', false

      # for locked row, all values are valid, regardless of actual value
      return true if @locked

      # initialize field validity by parse validity
      dateValid = not @$date.data('invalid')
      startValid = not @$start_time.data('invalid')
      endValid = not @$end_time.data('invalid')

      # also make sure start is before end
      start = @startAt()
      end = @endAt()
      if start and end and end <= start
        @$start_time.errorBox(I18n.t 'end_before_start_error', 'Start time must be before end time')
        startValid = false

      # and end is in the future
      if end and end < $.fudgeDateForProfileTimezone(new Date())
        @$end_time.errorBox(I18n.t 'ends_in_past_error', 'You cannot create an appointment slot that ends in the past')
        endValid = false

      # toggle error class on each as appropriate
      @$date.toggleClass 'error', not dateValid
      @$end_time.toggleClass 'error', not endValid
      @$start_time.toggleClass 'error', not startValid

      # valid if all are valid
      return dateValid and startValid and endValid

    timeToDate: (date, time) ->
      return unless date and time
      date = $.fudgeDateForProfileTimezone(date)
      time = $.fudgeDateForProfileTimezone(time)

      # set all three values at once to handle potential
      # conflicts in how month rollover happens
      time.setFullYear(
        date.getFullYear(),
        date.getMonth(),
        date.getDate()
      )

      return time

    startAt: ->
      date = @$date.data('unfudged-date')
      time = @$start_time.data('unfudged-date')
      @timeToDate(date, time)

    endAt: ->
      date = @$date.data('unfudged-date')
      time = @$end_time.data('unfudged-date')
      @timeToDate(date, time)

    getData: ->
      [@startAt(), @endAt(), !!@locked]

    blank: ->
      @$date.data('blank') and @$start_time.data('blank') and @$end_time.data('blank')

    incomplete: ->
      not @blank() and (@$date.data('blank') or @$start_time.data('blank') or @$end_time.data('blank'))
