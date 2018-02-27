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
import ReactDOM from 'react-dom'
import {findRenderedDOMComponentWithTag} from 'react-addons-test-utils'
import $ from 'jquery'
import DueDateCalendarPicker from 'jsx/due_dates/DueDateCalendarPicker'
import tz from 'timezone'
import french from 'timezone/fr_FR'
import I18nStubber from 'helpers/I18nStubber'
import fakeENV from 'helpers/fakeENV'

const wrapper = document.getElementById('fixtures')

QUnit.module('unlock_at DueDateCalendarPicker', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    this.clock = sinon.useFakeTimers()
    this.props = {
      dateType: 'unlock_at',
      dateValue: new Date(Date.UTC(2012, 1, 1, 7, 1, 0)),
      disabled: false,
      handleUpdate() {},
      inputClasses: 'date_field datePickerDateField DueDateInput',
      isFancyMidnight: false,
      labelledBy: 'foo',
      rowKey: 'nullnullnull'
    }
    const DueDateCalendarPickerElement = <DueDateCalendarPicker {...this.props} />
    this.dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, wrapper)
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(wrapper)
    return this.clock.restore()
  }
})

test('renders', function() {
  ok(this.dueDateCalendarPicker.isMounted())
})

test('formattedDate returns a date in the same format used by DatetimeField', function() {
  equal('Feb 1, 2012 7:01am', this.dueDateCalendarPicker.formattedDate())
})

test('formattedDate returns a localized Date', function() {
  const snapshot = tz.snapshot()
  tz.changeLocale(french, 'fr_FR', 'fr')
  I18nStubber.pushFrame()
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {
    'date.formats.medium': '%-d %b %Y',
    'time.formats.tiny': '%-k:%M'
  })
  equal('1 févr. 2012 7:01', this.dueDateCalendarPicker.formattedDate())
  I18nStubber.popFrame()
  tz.restore(snapshot)
})

test('call the update prop when changed', function() {
  const update = this.spy(this.props, 'handleUpdate')
  const DueDateCalendarPickerElement = <DueDateCalendarPicker {...this.props} />
  this.dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, wrapper)
  const dateInput = $(ReactDOM.findDOMNode(this.dueDateCalendarPicker))
    .find('.date_field')
    .datetime_field()[0]
  $(dateInput).val('tomorrow')
  $(dateInput).trigger('change')
  ok(update.calledOnce)
  return update.restore()
})

test('deals with empty inputs properly', function() {
  const update = this.spy(this.props, 'handleUpdate')
  const DueDateCalendarPickerElement = <DueDateCalendarPicker {...this.props} />
  this.dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, wrapper)
  const dateInput = $(ReactDOM.findDOMNode(this.dueDateCalendarPicker))
    .find('.date_field')
    .datetime_field()[0]
  $(dateInput).val('')
  $(dateInput).trigger('change')
  ok(update.calledWith(null))
  return update.restore()
})

test('does not convert to fancy midnight when isFancyMidnight is false', function() {
  // This date will be set to midnight in the time zone of the app.
  const date = tz.parse('2015-08-31T00:00:00')
  equal(this.dueDateCalendarPicker.changeToFancyMidnightIfNeeded(date), date)
})

QUnit.module('due_at DueDateCalendarPicker', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    this.clock = sinon.useFakeTimers()
    const props = {
      dateType: 'due_at',
      dateValue: new Date(Date.UTC(2012, 1, 1, 7, 0, 0)),
      disabled: false,
      handleUpdate() {},
      inputClasses: 'date_field datePickerDateField DueDateInput',
      isFancyMidnight: true,
      labelledBy: 'foo',
      rowKey: 'nullnullnull'
    }
    const DueDateCalendarPickerElement = <DueDateCalendarPicker {...props} />
    this.dueDateCalendarPicker = ReactDOM.render(
      DueDateCalendarPickerElement,
      $('<div>').appendTo('body')[0]
    )
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(wrapper)
    return this.clock.restore()
  }
})

test('converts to fancy midnight', function() {
  // This date will be set to midnight in the time zone of the app.
  let date = tz.parse('2015-08-31T00:00:00')
  date = this.dueDateCalendarPicker.changeToFancyMidnightIfNeeded(date)
  equal(date.getMinutes(), 59)
})

test('converts to fancy midnight in the time zone of the user', function() {
  // This date will be set to midnight in the time zone of the *user*.
  const snapshot = tz.snapshot()
  tz.changeZone('America/Chicago')
  let date = tz.parse('2015-08-31T00:00:00')
  date = this.dueDateCalendarPicker.changeToFancyMidnightIfNeeded(date)
  equal(date.getMinutes(), 59)
  tz.restore(snapshot)
})

QUnit.module('disabled DueDateCalendarPicker', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    const props = {
      dateType: 'unlock_at',
      dateValue: new Date(Date.UTC(2012, 1, 1, 7, 1, 0)),
      disabled: true,
      handleUpdate() {},
      inputClasses: 'date_field datePickerDateField DueDateInput',
      isFancyMidnight: true,
      labelledBy: 'foo',
      rowKey: 'foobar'
    }
    const DueDateCalendarPickerElement = <DueDateCalendarPicker {...props} />
    this.dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, wrapper)
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('sets the input as readonly', function() {
  const input = findRenderedDOMComponentWithTag(this.dueDateCalendarPicker, 'input')
  equal(input.readOnly, true)
})

test('disables the calendar picker button', function() {
  const button = findRenderedDOMComponentWithTag(this.dueDateCalendarPicker, 'button')
  ok(button.getAttribute('aria-disabled'), true)
})

QUnit.module('given isFancyMidnight false', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    this.clock = sinon.useFakeTimers()
    const props = {
      dateType: 'due_at',
      dateValue: new Date(Date.UTC(2012, 1, 1, 7, 0, 0)),
      disabled: false,
      handleUpdate() {},
      inputClasses: 'date_field datePickerDateField DueDateInput',
      isFancyMidnight: false,
      labelledBy: 'foo',
      rowKey: 'nullnullnull'
    }
    const DueDateCalendarPickerElement = <DueDateCalendarPicker {...props} />
    this.dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, wrapper)
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(wrapper)
    this.clock.restore()
  }
})

test('minutes remain unchanged', function() {
  const date = tz.parse('2015-08-31T00:00:00')
  const minutes = this.dueDateCalendarPicker.changeToFancyMidnightIfNeeded(date).getMinutes()
  equal(minutes, 0)
})
