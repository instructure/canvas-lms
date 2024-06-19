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
import CalendarHeader from '../CalendarHeader'
import {isAccessible} from '@canvas/test-utils/jestAssertions'

let header

describe('CalendarHeader', function () {
  beforeEach(function () {
    // set up fixtures
    $('<div id="fixtures"></div>').appendTo('body')
    header = new CalendarHeader()
    header.$el.appendTo($('#fixtures'))
  })

  afterEach(function () {
    header.$el.remove()
    $('#fixtures').empty()
  })

  // fails in Jest, passes in QUnit
  test.skip('it should be accessible', function (done) {
    isAccessible(header, done, {a11yReport: true})
  })

  test('#moveToCalendarViewButton clicks the next calendar view button', function (done) {
    const buttons = $('.calendar_view_buttons button')
    buttons.first().click()
    buttons.eq(1).on('click', () => {
      // 'next button was clicked'
      expect(true).toBeTruthy()
      done()
    })
    header.moveToCalendarViewButton('next')
  })

  test('#moveToCalendarViewButton wraps around to the first calendar view button', function (done) {
    const buttons = $('.calendar_view_buttons button')
    buttons.last().click()
    buttons.first().on('click', () => {
      // first button was clicked
      expect(true).toBeTruthy()
      done()
    })
    header.moveToCalendarViewButton('next')
  })

  test('#moveToCalendarViewButton clicks the previous calendar view button', function (done) {
    const buttons = $('.calendar_view_buttons button')
    buttons.last().click()
    buttons.eq(buttons.length - 2).on('click', () => {
      // previous button was clicked
      expect(true).toBeTruthy()
      done()
    })
    header.moveToCalendarViewButton('prev')
  })

  test('#moveToCalendarViewButton wraps around to the last calendar view button', function (done) {
    const buttons = $('.calendar_view_buttons button')
    buttons.first().click()
    buttons.last().on('click', () => {
      // last button was clicked
      expect(true).toBeTruthy()
      done()
    })
    header.moveToCalendarViewButton('prev')
  })

  test("calls #moveToCalendarViewButton with 'prev' when left key is pressed", function (done) {
    const {moveToCalendarViewButton} = header
    header.moveToCalendarViewButton = direction => {
      expect(direction).toBe('prev')
      header.moveToCalendarViewButton = moveToCalendarViewButton
      done()
    }
    const e = $.Event('keydown', {which: 37})
    $('.calendar_view_buttons').trigger(e)
  })

  test("calls #moveToCalendarViewButton with 'prev' when up key is pressed", function (done) {
    const {moveToCalendarViewButton} = header
    header.moveToCalendarViewButton = direction => {
      expect(direction).toBe('prev')
      header.moveToCalendarViewButton = moveToCalendarViewButton
      done()
    }
    const e = $.Event('keydown', {which: 38})
    $('.calendar_view_buttons').trigger(e)
  })

  test("calls #moveToCalendarViewButton with 'next' when right key is pressed", function (done) {
    const {moveToCalendarViewButton} = header
    header.moveToCalendarViewButton = direction => {
      expect(direction).toBe('next')
      header.moveToCalendarViewButton = moveToCalendarViewButton
      done()
    }
    const e = $.Event('keydown', {which: 39})
    $('.calendar_view_buttons').trigger(e)
  })

  test("calls #moveToCalendarViewButton with 'next' when down key is pressed", function (done) {
    const {moveToCalendarViewButton} = header
    header.moveToCalendarViewButton = direction => {
      expect(direction).toBe('next')
      header.moveToCalendarViewButton = moveToCalendarViewButton
      done()
    }
    const e = $.Event('keydown', {which: 40})
    $('.calendar_view_buttons').trigger(e)
  })

  test('when a calendar view button is clicked it is properly activated', function (done) {
    $('.calendar_view_buttons button')
      .last()
      .on('click', e => {
        header.toggleView(e)
        const button = $('.calendar_view_buttons button').last()
        expect(button.attr('aria-selected')).toBe('true')
        expect(button.attr('tabindex')).toBe('0')
        expect(button.hasClass('active')).toBeTruthy()
        button.siblings().each(function () {
          expect($(this).attr('aria-selected')).toBe('false')
          expect($(this).attr('tabindex')).toBe('-1')
          expect($(this).hasClass('active')).not.toBeTruthy()
        })
        done()
      })
    $('.calendar_view_buttons button').last().click()
  })
})
