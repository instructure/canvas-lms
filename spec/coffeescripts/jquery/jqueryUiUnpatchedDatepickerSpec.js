/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import 'jqueryui/datepicker'

QUnit.module('datepicker Widget', {
  beforeEach(assert) {
    assert = assert || QUnit.assert
    assert.ok($.fn.datepicker, 'Datepicker plugin is loaded')
    $('#fixtures').append('<input type="text" id="datepicker">')
    $('#datepicker').datepicker({
      // disable animations for more predictable test results
      showAnim: null,
    })
  },
  afterEach() {
    const $datepicker = $('#datepicker')
    $datepicker.datepicker('hide').datepicker('destroy').removeClass('hasDatepicker')
    // this breaks the tests, but it seems like it should be necessary
    // .datepicker('widget').remove() // widget = #ui-datepicker-div
    $('#fixtures').empty()
  },
})

QUnit.test('datepicker widget is initialized', function (assert) {
  const $datepicker = $('#datepicker')
  // check if the Datepicker widget is initialized by verifying the presence of the “hasDatepicker”
  // class, which is added to input fields initialized with the Datepicker widget in older versions
  // of jQuery UI
  if ($datepicker.hasClass('hasDatepicker')) {
    assert.ok(true, 'Datepicker widget is initialized')
  } else {
    // eslint-disable-next-line no-console
    console.warn(`
      Unable to determine if Datepicker widget is initialized.
      Please verify if the “hasDatepicker” class is added by the Datepicker plugin.
      Note that in newer versions of jQuery UI, the “hasDatepicker” class may have been removed.
    `)
    assert.ok(false, 'Datepicker widget is not initialized')
  }
})

QUnit.test('datepicker widget opens on focus', function (assert) {
  const $datepicker = $('#datepicker')
  $datepicker.datepicker('show')
  assert.ok($datepicker.datepicker('widget').is(':visible'), 'Datepicker opens on focus')
})

QUnit.skip('selecting a date updates the input field', function (assert) {
  const $datepicker = $('#datepicker')
  const date = new Date()
  $datepicker.datepicker('setDate', date)
  $datepicker.datepicker('show')
  const datepickerDate = $datepicker.datepicker('getDate')
  const expectedDate = new Date(date.setHours(0, 0, 0, 0))
  const actualDate = new Date(datepickerDate.setHours(0, 0, 0, 0))
  assert.equal(actualDate.getTime(), expectedDate.getTime(), 'Date selected matches input value')
})

QUnit.skip('navigating between months and selecting a date updates the input', function (assert) {
  const $datepicker = $('#datepicker')
  const currentDate = new Date()
  const currentMonth = currentDate.getMonth()
  $datepicker.datepicker('setDate', currentDate)
  $datepicker.datepicker('show')
  // find the initial month and year
  let $datepickerDiv = $datepicker.datepicker('widget')
  const initialMonth = $datepickerDiv.find('.ui-datepicker-month').text()
  // find the next and previous month buttons
  const $nextMonthButton = $datepickerDiv.find('.ui-datepicker-next')
  // navigate to the next month and check if it works
  $nextMonthButton.trigger('click')
  // re-select the next and previous month buttons after navigation
  $datepickerDiv = $datepicker.datepicker('widget')
  const $prevMonthButton = $datepickerDiv.find('.ui-datepicker-prev')
  // programmatically select the first day of the new month
  const newMonthFirstDaySelector =
    '.ui-datepicker-calendar tbody td:not(.ui-datepicker-other-month) a'
  const firstDayOfNewMonth = $datepickerDiv.find(newMonthFirstDaySelector).first()
  if (firstDayOfNewMonth.length) {
    firstDayOfNewMonth.trigger('click')
    // after selection, the input's value should be updated
    const newDate = $datepicker.datepicker('getDate')
    const newSelectedMonth = newDate.getMonth()
    assert.notEqual(
      newSelectedMonth,
      currentMonth,
      'Input value updated to the new month after selection'
    )
  } else {
    assert.ok(false, 'Could not find a day in the new month to select')
  }
  // navigate back to the current month and check if it works
  $prevMonthButton.trigger('click')
  // re-select the datepicker elements after navigation
  $datepickerDiv = $datepicker.datepicker('widget')
  const revertedMonth = $datepickerDiv.find('.ui-datepicker-month').text()
  assert.equal(revertedMonth, initialMonth, 'Navigating back to current month works')
})

QUnit.skip('datepicker getDate method returns valid date', function (assert) {
  const $datepicker = $('#datepicker')
  const knownDate = new Date()
  $datepicker.datepicker('setDate', knownDate)
  $datepicker.datepicker('show')
  const retrievedDate = $datepicker.datepicker('getDate')
  $datepicker.datepicker('hide')
  // console.log('Datepicker instance:', $('#datepicker').data('datepicker'))
  // console.log('Retrieved Date:', retrievedDate)
  // console.log('Type of Retrieved Date:', typeof retrievedDate)
  assert.ok(retrievedDate instanceof Date, 'The retrieved date should be an instance of Date')
  // normalize both dates to midnight for accurate comparison
  knownDate.setHours(0, 0, 0, 0)
  retrievedDate.setHours(0, 0, 0, 0)
  assert.equal(
    retrievedDate.getTime(),
    knownDate.getTime(),
    'The retrieved date matches the known date'
  )
})
