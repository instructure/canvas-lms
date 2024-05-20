// @vitest-environment jsdom
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, waitFor, fireEvent} from '@testing-library/react'
import DateTimeInput from '../DateTimeInput'
import {changeTimezone} from '../../../changeTimezone'

const sampleDateTime = '2021-04-07T15:00:00Z'
const locale = 'en-US'
const timezone = 'Pacific/Honolulu'

const dateFormatter = new Intl.DateTimeFormat(locale, {
  weekday: 'short',
  month: 'long',
  day: 'numeric',
  year: 'numeric',
  timezone,
})

const timeFormatter = new Intl.DateTimeFormat(locale, {
  hour: 'numeric',
  minute: 'numeric',
  timezone,
})

const props = {
  dateLabel: 'Date',
  timeLabel: 'Time',
  locale,
  timezone,
  onChange: Function.prototype,
  value: sampleDateTime,
  description: 'Pick a Date and Time',
}

function renderInput(overrides = {}) {
  const result = render(<DateTimeInput {...props} {...overrides} />)
  result.props = props
  return result
}

describe('DateTimeInput::', () => {
  it('sets the date and time labels', () => {
    const dateLabel = 'pickydate!'
    const timeLabel = 'pickytime!'
    const {getByLabelText} = renderInput({dateLabel, timeLabel})
    expect(getByLabelText(dateLabel)).toBeInTheDocument()
    expect(getByLabelText(timeLabel)).toBeInTheDocument()
  })

  it('handles nullish value as current date and time', () => {
    const now = changeTimezone(new Date(), {originTZ: timezone})
    const expDate = dateFormatter.format(now)
    const expTime = timeFormatter.format(now)
    const {getByDisplayValue} = renderInput({value: undefined})
    expect(getByDisplayValue(expDate)).toBeInTheDocument()
    expect(getByDisplayValue(expTime)).toBeInTheDocument()
  })

  it('has the correct initial form values', () => {
    const {getByDisplayValue} = renderInput()
    expect(getByDisplayValue('Wed, April 7, 2021')).toBeInTheDocument()
    expect(getByDisplayValue('5:00 AM')).toBeInTheDocument()
  })

  // FOO-3060 (08/16/2022)
  it.skip('displays the currently-selected date and time', () => {
    const {getAllByText} = renderInput()
    getAllByText('Wed, April 7, 2021, 5:00 AM') // should not throw
  })

  it('makes a good callback when the date is changed', async () => {
    const onChange = jest.fn()
    const {getByLabelText, queryAllByText, rerender} = renderInput({onChange})
    const dateInput = getByLabelText('Date')
    fireEvent.input(dateInput, {target: {value: 'Apr 10 2022'}})
    fireEvent.blur(dateInput)
    const callbackParm = onChange.mock.calls[0][0]
    expect(callbackParm).toBe('2022-04-10T15:00:00.000Z')
    rerender(<DateTimeInput {...props} onChange={onChange} value={callbackParm} />)
    await waitFor(() => expect(queryAllByText('Sat, April 10, 2021, 5:00 AM')).not.toBeNull())
  })

  it('makes a good callback when the time is changed', async () => {
    const onChange = jest.fn()
    const {getByLabelText, queryAllByText, rerender} = renderInput({onChange})
    const timeInput = getByLabelText('Time')
    fireEvent.click(timeInput)
    fireEvent.input(timeInput, {target: {value: '3:30 PM'}})
    fireEvent.keyDown(timeInput, {keyCode: 13})
    const callbackParm = onChange.mock.calls[0][0]
    expect(callbackParm).toBe('2021-04-08T01:30:00.000Z')
    rerender(<DateTimeInput {...props} onChange={onChange} value={callbackParm} />)
    await waitFor(() => expect(queryAllByText('Wed, April 7, 2021, 3:30 PM')).not.toBeNull())
  })

  // FOO-3060 (08/16/2022)
  it.skip('replaces the value when a new one is provided via props', () => {
    const {getByDisplayValue, getAllByText, rerender} = renderInput()
    getAllByText('Wed, April 7, 2021, 5:00 AM') // should not throw
    rerender(<DateTimeInput {...props} value="2022-01-01T14:00:00Z" />)
    expect(getByDisplayValue('Sat, January 1, 2022')).toBeInTheDocument()
    expect(getByDisplayValue('4:00 AM')).toBeInTheDocument()
    getAllByText('Sat, January 1, 2022, 4:00 AM') // should not throw
  })

  /*
   * We can't test this DST stuff, unfortunately, because the Intl package that
   * comes with Node.js has incomplete locale and TZ data.  :(
   * The DST behavior was however extensively tested manually.
   */

  it.skip('works when a DST boundary is crossed DT -> ST', () => {
    const dstProps = {...props, timezone: 'America/New_York'}
    const {getByLabelText, getByDisplayValue, getAllByText} = renderInput(dstProps)
    getAllByText('Wed, April 7, 2021, 11:00 AM') // should not throw
    expect(getByDisplayValue('Wed, April 7, 2021')).toBeInTheDocument()
    expect(getByDisplayValue('11:00 AM')).toBeInTheDocument()
    const dateInput = getByLabelText('Date')
    fireEvent.input(dateInput, {target: {value: 'Jan 1'}})
    fireEvent.blur(dateInput)
    expect(getByDisplayValue('Fri, January 1, 2021')).toBeInTheDocument()
    expect(getByDisplayValue('11:00 AM')).toBeInTheDocument()
  })

  it.skip('works when a DST boundary is crossed ST -> DT', () => {
    const dstProps = {...props, value: '2021-02-01T20:00:00Z', timezone: 'America/New_York'}
    const {getByDisplayValue, getAllByText, rerender} = renderInput(dstProps)
    getAllByText('Mon, February 1, 2021, 3:00 PM') // should not throw
    expect(getByDisplayValue('3:00 PM')).toBeInTheDocument()
    rerender(<DateTimeInput {...dstProps} value="2021-05-01T14:00:00Z" />)
    expect(getByDisplayValue('Sat, May 1, 2021')).toBeInTheDocument()
    expect(getByDisplayValue('10:00 AM')).toBeInTheDocument()
  })
})
