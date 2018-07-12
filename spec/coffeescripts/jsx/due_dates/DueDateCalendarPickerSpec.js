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
import {mount} from 'enzyme'
import chicago from 'timezone/America/Chicago'
import DueDateCalendarPicker from 'jsx/due_dates/DueDateCalendarPicker'
import tz from 'timezone'
import french from 'timezone/fr_FR'
import I18nStubber from 'helpers/I18nStubber'
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
      rowKey: 'nullnullnull'
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    clock.restore()
    fakeENV.teardown()
  })

  function mountComponent() {
    wrapper = mount(<DueDateCalendarPicker {...props} />)
  }

  function simulateChange(value) {
    const $dateField = wrapper.find('.date_field').getDOMNode()
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
    const snapshot = tz.snapshot()
    tz.changeZone(chicago, 'America/Chicago')
    simulateChange('2015-08-31T00:00:00')
    tz.restore(snapshot)
    equal(getEnteredDate().toUTCString(), 'Tue, 01 Sep 2015 04:59:59 GMT')
  })

  test('does not convert to fancy midnight when isFancyMidnight is false', () => {
    mountComponent()
    simulateChange('2015-08-31T00:00:00')
    equal(getEnteredDate().toUTCString(), 'Mon, 31 Aug 2015 00:00:00 GMT')
  })

  test('#formattedDate() returns a date in the same format used by DatetimeField', () => {
    mountComponent()
    equal(wrapper.instance().formattedDate(), 'Feb 1, 2012 7:01am')
  })

  test('#formattedDate() returns a localized Date', () => {
    mountComponent()
    const snapshot = tz.snapshot()
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.pushFrame()
    I18nStubber.setLocale('fr_FR')
    I18nStubber.stub('fr_FR', {
      'date.formats.medium': '%-d %b %Y',
      'time.formats.tiny': '%-k:%M'
    })
    equal(wrapper.instance().formattedDate(), '1 févr. 2012 7:01')
    I18nStubber.popFrame()
    tz.restore(snapshot)
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
    const $input = wrapper.find('input').getDOMNode()
    strictEqual($input.readOnly, true)
  })

  test('disables the calendar picker button when disabled is true', () => {
    props.disabled = true
    mountComponent()
    const $button = wrapper.getDOMNode().querySelector('button')
    equal($button.getAttribute('aria-disabled'), 'true')
  })

  test('forwards properties to label', () => {
    props.labelClasses = 'special-label'
    mountComponent()
    ok(wrapper.find('label').prop('className').match(/special-label/));
  })

  test('forwards properties to input', () => {
    props.name = 'special-name'
    mountComponent()
    ok(wrapper.find('input').prop('name').match(/special-name/));
  })

  test('label and input reference each other', () => {
    mountComponent()

    const htmlFor = wrapper.find('label').prop('htmlFor')
    const inputId = wrapper.find('input').prop('id')
    equal(htmlFor, inputId)

    const labelId = wrapper.find('label').prop('id')
    const labelledby = wrapper.find('input').prop('aria-labelledby')
    equal(labelId, labelledby)
  })
})
