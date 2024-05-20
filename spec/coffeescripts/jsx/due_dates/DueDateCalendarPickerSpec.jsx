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

import React from 'react'
import {render} from '@testing-library/react'
import chicago from 'timezone/America/Chicago'
import DueDateCalendarPicker from '@canvas/due-dates/react/DueDateCalendarPicker'
import * as tz from '@canvas/datetime'
import tzInTest from '@canvas/datetime/specHelpers'
import fakeENV from 'helpers/fakeENV'

QUnit.module('DueDateCalendarPicker', suiteHooks => {
  let clock
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    clock = sinon.useFakeTimers()

    props = {
      dateType: 'unlock_at',
      dateValue: new Date(Date.UTC(2012, 1, 1, 7, 1, 0)),
      disabled: false,
      handleUpdate: sinon.spy(),
      inputClasses: 'date_field datePickerDateField DueDateInput',
      isFancyMidnight: false,
      labelText: 'bar',
      labelledBy: 'foo',
      rowKey: 'nullnullnull',
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    clock.restore()
    fakeENV.teardown()
    tzInTest.restore()
  })

  function mountComponent() {
    wrapper = render(<DueDateCalendarPicker {...props} />)
  }

  function simulateChange(value) {
    const $dateField = wrapper.container.querySelector('.date_field')
    $dateField.value = value
    $dateField.dispatchEvent(new Event('change'))
  }

  function getEnteredDate() {
    const [date] = props.handleUpdate.lastCall.args
    return tz.parse(date)
  }

  test('converts to fancy midnight when isFancyMidnight is true', () => {
    props.isFancyMidnight = true
    mountComponent()
    simulateChange('2015-08-31T00:00:00')
    strictEqual(getEnteredDate().getMinutes(), 59)
  })

  test('converts to fancy midnight in the timezone of the user', () => {
    props.isFancyMidnight = true
    mountComponent()
    tzInTest.changeZone(chicago, 'America/Chicago')
    simulateChange('2015-08-31T00:00:00')
    equal(getEnteredDate().toUTCString(), 'Tue, 01 Sep 2015 04:59:59 GMT')
  })

  test('sets the default time (if provided) in the timezone of the user', () => {
    props.defaultTime = '16:22:22'
    props.isFancyMidnight = true
    mountComponent()
    tzInTest.changeZone(chicago, 'America/Chicago')
    simulateChange('2022-02-22')
    equal(getEnteredDate().toUTCString(), 'Tue, 22 Feb 2022 22:22:22 GMT')
  })

  test('does not convert to fancy midnight when isFancyMidnight is false', () => {
    mountComponent()
    simulateChange('2015-08-31T00:00:00')
    equal(getEnteredDate().toUTCString(), 'Mon, 31 Aug 2015 00:00:00 GMT')
  })

  test('call the update prop when changed', () => {
    mountComponent()
    simulateChange('tomorrow')
    strictEqual(props.handleUpdate.callCount, 1)
  })

  test('calls the handleUpdate prop with null when an empty string is entered', () => {
    mountComponent()
    simulateChange('')
    strictEqual(getEnteredDate(), null)
  })

  test('sets the input as readonly when disabled is true', () => {
    props.disabled = true
    mountComponent()
    const $input = wrapper.container.querySelector('input')
    strictEqual($input.readOnly, true)
  })

  test('disables the calendar picker button when disabled is true', () => {
    props.disabled = true
    mountComponent()
    const $button = wrapper.container.querySelector('button')
    equal($button.getAttribute('aria-disabled'), 'true')
  })

  test('forwards properties to label', () => {
    props.labelClasses = 'special-label'
    mountComponent()
    ok(
      wrapper
        .container.querySelector('label')
        .className
        .match(/special-label/)
    )
  })

  test('forwards properties to input', () => {
    props.name = 'special-name'
    mountComponent()
    ok(
      wrapper
        .container.querySelector('input')
        .name
        .match(/special-name/)
    )
  })

  test('label and input reference each other', () => {
    mountComponent()

    const htmlFor = wrapper.container.querySelector('label').htmlFor
    const inputId = wrapper.container.querySelector('input').id
    equal(htmlFor, inputId)

    const labelId = wrapper.container.querySelector('label').id
    const labelledby = wrapper.container.querySelector('input').getAttribute('aria-labelledby')
    equal(labelId, labelledby)
  })

  test('sets seconds to 59 when defaultToEndOfMinute is true and seconds value is 0', () => {
    props.defaultToEndOfMinute = true
    mountComponent()

    simulateChange('2015-08-31T00:30:00')
    equal(getEnteredDate().toUTCString(), 'Mon, 31 Aug 2015 00:30:59 GMT')
  })

  test('does not set seconds value when defaultToEndOfMinute is true and seconds value is not 0', () => {
    props.defaultToEndOfMinute = true
    mountComponent()

    simulateChange('2015-08-31T00:30:10')
    equal(getEnteredDate().toUTCString(), 'Mon, 31 Aug 2015 00:30:10 GMT')
  })

  test('does not adjust seconds value when defaultToEndOfMinute is not true', () => {
    mountComponent()

    simulateChange('2015-08-31T00:30:00')
    equal(getEnteredDate().toUTCString(), 'Mon, 31 Aug 2015 00:30:00 GMT')
  })
})
