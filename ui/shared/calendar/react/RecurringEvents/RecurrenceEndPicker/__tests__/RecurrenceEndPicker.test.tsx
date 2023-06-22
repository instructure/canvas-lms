/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, act, fireEvent, screen, waitFor} from '@testing-library/react'
import moment from 'moment-timezone'
import {UnknownSubset} from '../../types'
import RecurrenceEndPicker, {RecurrenceEndPickerProps} from '../RecurrenceEndPicker'

const defaultTZ = 'Asia/Tokyo'
const today = moment().tz(defaultTZ)

export function formatDate(date: Date, locale: string, timezone: string) {
  return new Intl.DateTimeFormat('en', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    timeZone: timezone,
  }).format(date)
}

export function makeSimpleIsoDate(date: moment.Moment): string {
  return date.format('YYYY-MM-DDTHH:mm:ssZ')
}

export async function changeUntilDate(
  enddate: moment.Moment,
  newenddate: moment.Moment,
  locale: string,
  timezone: string
) {
  const displayedUntil = formatDate(enddate.toDate(), locale, timezone)
  const dateinput = screen.getByDisplayValue(displayedUntil)
  const newEndDateStr = formatDate(newenddate.toDate(), locale, timezone)
  act(() => {
    fireEvent.change(dateinput, {target: {value: newEndDateStr}})
  })
  await waitFor(() => screen.getByDisplayValue(newEndDateStr))
  act(() => {
    fireEvent.blur(dateinput)
  })
}

const defaultProps = (
  overrides: UnknownSubset<RecurrenceEndPickerProps> = {}
): RecurrenceEndPickerProps => ({
  locale: 'en',
  timezone: defaultTZ,
  dtstart: today.format('YYYY-MM-DDTHH:mm:ssZ'),
  courseEndAt: undefined,
  until: undefined,
  count: undefined,
  onChange: () => {},
  ...overrides,
})

describe('RecurrenceEndPicker', () => {
  beforeEach(() => {
    moment.tz.setDefault(defaultTZ)
  })

  it('renders', () => {
    const props = {...defaultProps()}
    const {getByDisplayValue, getByText, getAllByText} = render(<RecurrenceEndPicker {...props} />)

    expect(getAllByText('Ends:')).toHaveLength(2)
    // the radio buttons
    expect(getByText('on')).toBeInTheDocument()
    expect(getByDisplayValue('ON')).toBeInTheDocument()
    expect(getByText('after')).toBeInTheDocument()
    expect(getByDisplayValue('AFTER')).toBeInTheDocument()

    expect(getByDisplayValue('5')).toBeInTheDocument()
    const until = formatDate(today.clone().add(1, 'year').toDate(), props.locale, props.timezone)
    expect(getByDisplayValue(until)).toBeInTheDocument()
  })

  it('fires onChange when the radio buttons are clicked', () => {
    const onChange = jest.fn()
    const enddate = today.clone().add(5, 'days').format('YYYY-MM-DD')
    const {getByDisplayValue} = render(
      <RecurrenceEndPicker {...defaultProps({onChange, until: enddate})} />
    )

    act(() => {
      fireEvent.click(getByDisplayValue('AFTER'))
    })

    expect(onChange).toHaveBeenCalledWith({count: 5})
  })

  it('fires onChange when the date input is changed', async () => {
    const onChange = jest.fn()
    const enddate = today.clone().add(5, 'days')
    const props = {...defaultProps({onChange, until: makeSimpleIsoDate(enddate)})}
    render(<RecurrenceEndPicker {...props} />)

    const newEndDate = enddate.clone().add(1, 'day')
    await changeUntilDate(enddate, newEndDate, props.locale, props.timezone)

    expect(onChange).toHaveBeenCalledWith({
      until: newEndDate.startOf('day').format('YYYY-MM-DDTHH:mm:ssZ'),
      count: undefined,
    })
  })

  it('fires onChange when the count input is changed', async () => {
    const onChange = jest.fn()
    const props = {...defaultProps({onChange, count: 5})}
    const {getByDisplayValue} = render(<RecurrenceEndPicker {...props} />)

    const countinput = getByDisplayValue('5')
    act(() => {
      fireEvent.change(countinput, {target: {value: '6'}})
    })

    expect(onChange).toHaveBeenCalledWith({
      until: undefined,
      count: 6,
    })
  })
})
