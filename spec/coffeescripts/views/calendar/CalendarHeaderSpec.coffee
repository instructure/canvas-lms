#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'compiled/views/calendar/CalendarHeader'
  'helpers/assertions'
], ($, CalendarHeader, assertions) ->

  QUnit.module 'CalendarHeader',
    setup: ->
      @header = new CalendarHeader()
      @header.$el.appendTo $('#fixtures')

    teardown: ->
      @header.$el.remove()
      $("#fixtures").empty()

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @header, done, {'a11yReport': true}

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

