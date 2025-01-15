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

import React from 'react'
import {render, screen} from '@testing-library/react'
import chicago from 'timezone/America/Chicago'
import DueDateCalendarPicker from '../DueDateCalendarPicker'
import * as tz from '@instructure/moment-utils'
import tzInTest from '@instructure/moment-utils/specHelpers'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('DueDateCalendarPicker', () => {
  const defaultProps = {
    dateType: 'unlock_at',
    dateValue: new Date(Date.UTC(2012, 1, 1, 7, 1, 0)),
    disabled: false,
    handleUpdate: jest.fn(),
    inputClasses: 'date_field datePickerDateField DueDateInput',
    isFancyMidnight: false,
    labelText: 'bar',
    labelledBy: 'foo',
    rowKey: 'nullnullnull',
  }

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    jest.useFakeTimers()
  })

  afterEach(() => {
    fakeENV.teardown()
    tzInTest.restore()
    jest.clearAllMocks()
    jest.useRealTimers()
  })

  const renderComponent = (props = {}) => {
    return render(<DueDateCalendarPicker {...defaultProps} {...props} />)
  }

  const simulateChange = (element, value) => {
    element.value = value
    element.dispatchEvent(new Event('change'))
  }

  const getEnteredDate = () => {
    const [date] = defaultProps.handleUpdate.mock.lastCall
    return tz.parse(date)
  }

  it('converts to fancy midnight when isFancyMidnight is true', () => {
    renderComponent({isFancyMidnight: true})
    const dateField = screen.getByRole('textbox')
    simulateChange(dateField, '2015-08-31T00:00:00')
    expect(getEnteredDate().getMinutes()).toBe(59)
  })

  it('converts to fancy midnight in the timezone of the user', () => {
    renderComponent({isFancyMidnight: true})
    tzInTest.changeZone(chicago, 'America/Chicago')
    const dateField = screen.getByRole('textbox')
    simulateChange(dateField, '2015-08-31T00:00:00')
    expect(getEnteredDate().toUTCString()).toBe('Tue, 01 Sep 2015 04:59:59 GMT')
  })

  it('sets the default time in the timezone of the user', () => {
    renderComponent({
      defaultTime: '16:22:22',
      isFancyMidnight: true,
    })
    tzInTest.changeZone(chicago, 'America/Chicago')
    const dateField = screen.getByRole('textbox')
    simulateChange(dateField, '2022-02-22')
    expect(getEnteredDate().toUTCString()).toBe('Tue, 22 Feb 2022 22:22:22 GMT')
  })

  it('does not convert to fancy midnight when isFancyMidnight is false', () => {
    renderComponent()
    const dateField = screen.getByRole('textbox')
    simulateChange(dateField, '2015-08-31T00:00:00')
    expect(getEnteredDate().toUTCString()).toBe('Mon, 31 Aug 2015 00:00:00 GMT')
  })

  it('calls the update prop when changed', () => {
    renderComponent()
    const dateField = screen.getByRole('textbox')
    simulateChange(dateField, 'tomorrow')
    expect(defaultProps.handleUpdate).toHaveBeenCalled()
  })

  it('calls the handleUpdate prop with null when an empty string is entered', () => {
    renderComponent()
    const dateField = screen.getByRole('textbox')
    simulateChange(dateField, '')
    expect(getEnteredDate()).toBeNull()
  })

  it('sets the input as readonly when disabled is true', () => {
    renderComponent({disabled: true})
    const input = screen.getByRole('textbox')
    expect(input).toHaveAttribute('readonly')
  })

  it('disables the calendar picker button when disabled is true', () => {
    renderComponent({disabled: true})
    const button = screen.getByRole('button', {hidden: true})
    expect(button).toHaveAttribute('aria-disabled', 'true')
  })

  it('forwards properties to label', () => {
    renderComponent({labelClasses: 'special-label'})
    const label = screen.getByText('bar')
    expect(label).toHaveClass('special-label')
  })

  it('forwards properties to input', () => {
    renderComponent({name: 'special-name'})
    const input = screen.getByRole('textbox')
    expect(input).toHaveAttribute('name', 'special-name')
  })

  it('ensures label and input reference each other', () => {
    renderComponent()
    const label = screen.getByText('bar')
    const input = screen.getByRole('textbox')
    expect(input).toHaveAttribute('aria-labelledby', label.id)
  })

  it('sets seconds to 59 when defaultToEndOfMinute is true and seconds value is 0', () => {
    renderComponent({defaultToEndOfMinute: true})
    const dateField = screen.getByRole('textbox')
    simulateChange(dateField, '2015-08-31T00:30:00')
    expect(getEnteredDate().toUTCString()).toBe('Mon, 31 Aug 2015 00:30:59 GMT')
  })

  it('does not set seconds value when defaultToEndOfMinute is true and seconds value is not 0', () => {
    renderComponent({defaultToEndOfMinute: true})
    const dateField = screen.getByRole('textbox')
    simulateChange(dateField, '2015-08-31T00:30:10')
    expect(getEnteredDate().toUTCString()).toBe('Mon, 31 Aug 2015 00:30:10 GMT')
  })

  it('does not adjust seconds value when defaultToEndOfMinute is not true', () => {
    renderComponent()
    const dateField = screen.getByRole('textbox')
    simulateChange(dateField, '2015-08-31T00:30:00')
    expect(getEnteredDate().toUTCString()).toBe('Mon, 31 Aug 2015 00:30:00 GMT')
  })
})
