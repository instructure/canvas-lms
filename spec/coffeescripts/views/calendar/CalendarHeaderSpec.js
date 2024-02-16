/* eslint-disable qunit/resolve-async */
/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import 'jquery-migrate'
import CalendarHeader from 'ui/features/calendar/backbone/views/CalendarHeader'
import assertions from 'helpers/assertions'

QUnit.module('CalendarHeader', {
  setup() {
    this.header = new CalendarHeader()
    return this.header.$el.appendTo($('#fixtures'))
  },
  teardown() {
    this.header.$el.remove()
    $('#fixtures').empty()
  },
})

test('it should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(this.header, done, {a11yReport: true})
})

test('#moveToCalendarViewButton clicks the next calendar view button', function (assert) {
  const done = assert.async()
  const buttons = $('.calendar_view_buttons button')
  buttons.first().click()
  buttons.eq(1).on('click', () => {
    ok(true, 'next button was clicked')
    return done()
  })
  return this.header.moveToCalendarViewButton('next')
})

test('#moveToCalendarViewButton wraps around to the first calendar view button', function (assert) {
  const done = assert.async()
  const buttons = $('.calendar_view_buttons button')
  buttons.last().click()
  buttons.first().on('click', () => {
    ok(true, 'first button was clicked')
    return done()
  })
  return this.header.moveToCalendarViewButton('next')
})

test('#moveToCalendarViewButton clicks the previous calendar view button', function (assert) {
  const done = assert.async()
  const buttons = $('.calendar_view_buttons button')
  buttons.last().click()
  buttons.eq(buttons.length - 2).on('click', () => {
    ok(true, 'previous button was clicked')
    return done()
  })
  return this.header.moveToCalendarViewButton('prev')
})

test('#moveToCalendarViewButton wraps around to the last calendar view button', function (assert) {
  const done = assert.async()
  const buttons = $('.calendar_view_buttons button')
  buttons.first().click()
  buttons.last().on('click', () => {
    ok(true, 'last button was clicked')
    return done()
  })
  return this.header.moveToCalendarViewButton('prev')
})

test("calls #moveToCalendarViewButton with 'prev' when left key is pressed", function (assert) {
  const done = assert.async()
  const {moveToCalendarViewButton} = this.header
  this.header.moveToCalendarViewButton = direction => {
    equal(direction, 'prev')
    this.header.moveToCalendarViewButton = moveToCalendarViewButton
    return done()
  }
  const e = $.Event('keydown', {which: 37})
  return $('.calendar_view_buttons').trigger(e)
})

test("calls #moveToCalendarViewButton with 'prev' when up key is pressed", function (assert) {
  const done = assert.async()
  const {moveToCalendarViewButton} = this.header
  this.header.moveToCalendarViewButton = direction => {
    equal(direction, 'prev')
    this.header.moveToCalendarViewButton = moveToCalendarViewButton
    return done()
  }
  const e = $.Event('keydown', {which: 38})
  return $('.calendar_view_buttons').trigger(e)
})

test("calls #moveToCalendarViewButton with 'next' when right key is pressed", function (assert) {
  const done = assert.async()
  const {moveToCalendarViewButton} = this.header
  this.header.moveToCalendarViewButton = direction => {
    equal(direction, 'next')
    this.header.moveToCalendarViewButton = moveToCalendarViewButton
    return done()
  }
  const e = $.Event('keydown', {which: 39})
  return $('.calendar_view_buttons').trigger(e)
})

test("calls #moveToCalendarViewButton with 'next' when down key is pressed", function (assert) {
  const done = assert.async()
  const {moveToCalendarViewButton} = this.header
  this.header.moveToCalendarViewButton = direction => {
    equal(direction, 'next')
    this.header.moveToCalendarViewButton = moveToCalendarViewButton
    return done()
  }
  const e = $.Event('keydown', {which: 40})
  return $('.calendar_view_buttons').trigger(e)
})

test('when a calendar view button is clicked it is properly activated', function (assert) {
  const done = assert.async()
  $('.calendar_view_buttons button')
    .last()
    .on('click', e => {
      this.header.toggleView(e)
      const button = $('.calendar_view_buttons button').last()
      equal(button.attr('aria-selected'), 'true')
      equal(button.attr('tabindex'), '0')
      ok(button.hasClass('active'))
      button.siblings().each(function () {
        equal($(this).attr('aria-selected'), 'false')
        equal($(this).attr('tabindex'), '-1')
        notOk($(this).hasClass('active'))
      })
      return done()
    })
  return $('.calendar_view_buttons button').last().click()
})
