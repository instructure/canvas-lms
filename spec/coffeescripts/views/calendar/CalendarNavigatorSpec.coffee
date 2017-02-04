define [
  'jquery'
  'compiled/views/calendar/CalendarNavigator'
], ($, CalendarNavigator) ->

  QUnit.module 'CalendarNavigator',
    setup: ->
      @navigator = new CalendarNavigator()
      @navigator.$el.appendTo $('#fixtures')

    teardown: ->
      @navigator.$el.remove()
      $("#fixtures").empty()
      $("#ui-datepicker-div").empty()
      $(".ui-dialog").remove()
      $("ul[id^=ui-id-]").remove()

  test 'clicking a day in picker navigates to that date', ->
    # instrument the callback
    handler = @spy()
    @navigator.on('navigateDate', handler)

    # find and click a date other than today (typically tomorrow, but maybe
    # yesterday if we're at the end of the month)
    @navigator.$title.click()
    $today = $('.ui-datepicker-today')
    $sibling = $today.next('td')
    if !$sibling.length or !$('a.ui-state-default', $sibling).length
      $sibling = $today.prev('td')
      if !$sibling.length or !$('a.ui-state-default', $sibling).length
        ok false, 'expected to find a link for today or yesterday'
        return
    $('a.ui-state-default', $sibling).click()

    # the date we expect to have clicked
    month = $sibling.data('month')
    year = $sibling.data('year')
    day = $sibling.text()
    expectedDate = $.unfudgeDateForProfileTimezone(new Date(year, month, day))

    # check that we got the expected value to the callback
    equal +handler.getCall(0).args[0], +expectedDate

  test 'hitting enter in date field navigates to date', ->
    # instrument the callback
    handler = @spy()
    @navigator.on('navigateDate', handler)

    # type and "enter" a date
    @navigator.$title.click()
    $dateField = @navigator.$dateField
    $dateField.val("July 4, 2015")
    $dateField.trigger($.Event('keydown', keyCode: 13))

    # check that we got the expected value to the callback
    expectedDate = $.unfudgeDateForProfileTimezone(new Date(2015, 6, 4))
    equal +handler.getCall(0).args[0], +expectedDate
