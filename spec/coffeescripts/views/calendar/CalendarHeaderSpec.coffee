define [
  'jquery'
  'compiled/views/calendar/CalendarHeader'
], ($, CalendarHeader) ->

  QUnit.module 'CalendarHeader',
    setup: ->
      @header = new CalendarHeader()
      @header.$el.appendTo $('#fixtures')

    teardown: ->
      @header.$el.remove()
      $("#fixtures").empty()

  test '#moveToCalendarViewButton clicks the next calendar view button', (assert) ->
    done = assert.async()
    buttons = $('.calendar_view_buttons button')
    buttons.first().click()
    buttons.eq(1).on('click', ->
      ok true, "next button was clicked"
      done()
    )

    @header.moveToCalendarViewButton('next')

  test '#moveToCalendarViewButton wraps around to the first calendar view button', (assert) ->
    done = assert.async()
    buttons = $('.calendar_view_buttons button')
    buttons.last().click()

    buttons.first().on('click', ->
      ok true, "first button was clicked"
      done()
    )

    @header.moveToCalendarViewButton('next')

  test '#moveToCalendarViewButton clicks the previous calendar view button', (assert) ->
    done = assert.async()
    buttons = $('.calendar_view_buttons button')
    buttons.last().click()
    buttons.eq(buttons.length - 2).on('click', ->
      ok true, "previous button was clicked"
      done()
    )

    @header.moveToCalendarViewButton('prev')

  test '#moveToCalendarViewButton wraps around to the last calendar view button', (assert) ->
    done = assert.async()
    buttons = $('.calendar_view_buttons button')
    buttons.first().click()

    buttons.last().on('click', ->
      ok true, "last button was clicked"
      done()
    )

    @header.moveToCalendarViewButton('prev')

  test "calls #moveToCalendarViewButton with 'prev' when left key is pressed", (assert) ->
    done = assert.async()
    moveToCalendarViewButton = @header.moveToCalendarViewButton
    @header.moveToCalendarViewButton = (direction) =>
      equal direction, 'prev'
      @header.moveToCalendarViewButton = moveToCalendarViewButton
      done()
    e = $.Event('keydown', { which: 37 })
    $('.calendar_view_buttons').trigger(e)

  test "calls #moveToCalendarViewButton with 'prev' when up key is pressed", (assert) ->
    done = assert.async()
    moveToCalendarViewButton = @header.moveToCalendarViewButton
    @header.moveToCalendarViewButton = (direction) =>
      equal direction, 'prev'
      @header.moveToCalendarViewButton = moveToCalendarViewButton
      done()
    e = $.Event('keydown', { which: 38 })
    $('.calendar_view_buttons').trigger(e)

  test "calls #moveToCalendarViewButton with 'next' when right key is pressed", (assert) ->
    done = assert.async()
    moveToCalendarViewButton = @header.moveToCalendarViewButton
    @header.moveToCalendarViewButton = (direction) =>
      equal direction, 'next'
      @header.moveToCalendarViewButton = moveToCalendarViewButton
      done()
    e = $.Event('keydown', { which: 39 })
    $('.calendar_view_buttons').trigger(e)

  test "calls #moveToCalendarViewButton with 'next' when down key is pressed", (assert) ->
    done = assert.async()
    moveToCalendarViewButton = @header.moveToCalendarViewButton
    @header.moveToCalendarViewButton = (direction) =>
      equal direction, 'next'
      @header.moveToCalendarViewButton = moveToCalendarViewButton
      done()
    e = $.Event('keydown', { which: 40 })
    $('.calendar_view_buttons').trigger(e)

  test 'when a calendar view button is clicked it is properly activated', (assert) ->
    done = assert.async()
    $('.calendar_view_buttons button').last().on 'click', (e) =>
      @header.toggleView(e)

      button = $('.calendar_view_buttons button').last()
      equal button.attr('aria-selected'), 'true'
      equal button.attr('tabindex'), '0'
      ok button.hasClass('active')

      button.siblings().each ->
        equal $(this).attr('aria-selected'), 'false'
        equal $(this).attr('tabindex'), '-1'
        notOk $(this).hasClass('active')

      done()

    $('.calendar_view_buttons button').last().click()

