/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import CalendarNavigator from 'ui/features/calendar/backbone/views/CalendarNavigator'
import assertions from 'helpers/assertions'

QUnit.module('CalendarNavigator', {
  setup() {
    this.navigator = new CalendarNavigator()
    this.navigator.$el.appendTo($('#fixtures'))
  },

  teardown() {
    this.navigator.$el.remove()
    $('#fixtures').empty()
    $('#ui-datepicker-div').empty()
    $('.ui-dialog').remove()
    $('ul[id^=ui-id-]').remove()
  },
})

test('should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(this.navigator, () => done(), {a11yReport: true})
})

// TODO: LF-626 started failing only in Jenkins when unrelated code was removed
QUnit.skip('clicking a day in picker navigates to that date', function () {
  // instrument the callback
  const handler = sinon.spy()
  this.navigator.on('navigateDate', handler)

  // navigate to a known month
  this.navigator.$title.click()
  const {$dateField} = this.navigator
  $dateField.val('January, 2023')

  // select a day in the middle of a week and click the next day
  const midWeekDayNumber = 18 // non-zero indexed month day number
  const $today = $('tbody tr td', '.ui-datepicker-calendar').eq(midWeekDayNumber - 1) // Wednesday
  const $sibling = $today.next('td') // Thursday
  $('a.ui-state-default', $sibling).click()

  // the date we expect to have clicked
  const year = $sibling.data('year')
  const month = $sibling.data('month')
  const day = $sibling.text()
  const expectedDate = $.unfudgeDateForProfileTimezone(new Date(year, month, day))

  // check that we got the expected value to the callback
  equal(+handler.getCall(0).args[0], +expectedDate)
})

QUnit.skip('hitting enter in date field navigates to date', function () {
  // instrument the callback
  const handler = sinon.spy()
  this.navigator.on('navigateDate', handler)

  // type and "enter" a date
  this.navigator.$title.click()
  const {$dateField} = this.navigator
  $dateField.val('July 4, 2015')
  $dateField.trigger($.Event('keydown', {keyCode: 13}))

  // check that we got the expected value to the callback
  const expectedDate = $.unfudgeDateForProfileTimezone(new Date(2015, 6, 4))
  equal(+handler.getCall(0).args[0], +expectedDate)
})
