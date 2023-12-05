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
import {render, act, fireEvent} from '@testing-library/react'
import moment from 'moment-timezone'
import type {UnknownSubset} from '../../types'
import type {RRuleHelperSpec} from '../../RRuleHelper'
import {
  formatDate,
  makeSimpleIsoDate,
  changeUntilDate,
} from '../../RecurrenceEndPicker/__tests__/RecurrenceEndPicker.test'
import {changeFreq} from '../../RepeatPicker/__tests__/RepeatPicker.test'
import {weekdaysFromMoment} from '../../utils'
import CustomRecurrence, {type CustomRecurrenceProps} from '../CustomRecurrence'

const defaultTZ = 'Asia/Tokyo'
const today = moment().tz(defaultTZ)

const defaultProps = (
  overrides: UnknownSubset<CustomRecurrenceProps> = {},
  specOverrides: UnknownSubset<RRuleHelperSpec> = {}
): CustomRecurrenceProps => ({
  locale: 'en',
  timezone: defaultTZ,
  eventStart: makeSimpleIsoDate(today),
  courseEndAt: undefined,
  rruleSpec: {
    freq: 'DAILY',
    interval: 1,
    weekdays: undefined,
    month: undefined,
    monthdate: undefined,
    pos: undefined,
    until: undefined,
    count: undefined,
    ...specOverrides,
  },
  onChange: () => {},
  ...overrides,
})

describe('CustomRecurrence', () => {
  beforeEach(() => {
    moment.tz.setDefault(defaultTZ)
  })

  it('renders', () => {
    const props = {...defaultProps()}
    const {getByText, getAllByText, getByDisplayValue} = render(<CustomRecurrence {...props} />)

    expect(getByText('Repeat every:')).toBeInTheDocument()

    // interval
    expect(getByText('every')).toBeInTheDocument()
    expect(getByDisplayValue('1')).toBeInTheDocument()
    // frequency
    expect(getByText('date')).toBeInTheDocument()
    expect(getByDisplayValue('Day')).toBeInTheDocument()

    expect(getAllByText('Ends:').length).toBeGreaterThan(0)
    // the radio buttons
    expect(getByText('on')).toBeInTheDocument()
    expect(getByDisplayValue('ON')).toBeInTheDocument()
    expect(getByText('after')).toBeInTheDocument()
    expect(getByDisplayValue('AFTER')).toBeInTheDocument()

    // count
    expect(getByDisplayValue('5')).toBeInTheDocument()

    // until
    expect(getByText('date')).toBeInTheDocument()
    const until = formatDate(today.clone().add(1, 'year').toDate(), props.locale, props.timezone)
    expect(getByDisplayValue(until)).toBeInTheDocument()
  })

  it('fires onChange when interval changes', () => {
    const onChange = jest.fn()
    const props = {...defaultProps({onChange}, {count: 5})}
    const {getByDisplayValue} = render(<CustomRecurrence {...props} />)

    const interval = getByDisplayValue('1')
    fireEvent.change(interval, {target: {value: '2'}})

    expect(onChange).toHaveBeenCalledWith({
      ...props.rruleSpec,
      interval: 2,
    })
  })

  it('fires onChange when freq changes', () => {
    const onChange = jest.fn()
    const props = {...defaultProps({onChange}, {count: 5})}
    render(<CustomRecurrence {...props} />)

    changeFreq('Day', 'Week')

    expect(onChange).toHaveBeenCalledWith({
      ...props.rruleSpec,
      freq: 'WEEKLY',
      weekdays: weekdaysFromMoment(today),
    })
  })

  it('fires onChange when count changes', () => {
    const onChange = jest.fn()
    const props = {...defaultProps({onChange}, {count: 5})}
    const {getByDisplayValue} = render(<CustomRecurrence {...props} />)

    const countinput = getByDisplayValue('5')
    act(() => {
      fireEvent.change(countinput, {target: {value: '6'}})
    })

    expect(onChange).toHaveBeenCalledWith({
      ...props.rruleSpec,
      count: 6,
    })
  })

  it('fires onChange when until changes', async () => {
    const onChange = jest.fn()
    const endDate = today.clone().add(1, 'year')
    const props = {...defaultProps({onChange}, {until: makeSimpleIsoDate(endDate)})}
    render(<CustomRecurrence {...props} />)

    const newEndDate = today.clone().add(2, 'year')
    await changeUntilDate(endDate, newEndDate, props.locale, props.timezone)

    expect(onChange).toHaveBeenCalledWith({
      ...props.rruleSpec,
      until: newEndDate.endOf('day').format('YYYY-MM-DDTHH:mm:ssZ'),
    })
  })

  it('fires onChange when end type changes', () => {
    const onChange = jest.fn()
    const props = {...defaultProps({onChange}, {count: 5})}
    const {getByDisplayValue} = render(<CustomRecurrence {...props} />)

    const after = getByDisplayValue('ON')
    fireEvent.click(after)

    expect(onChange).toHaveBeenCalledWith({
      ...props.rruleSpec,
      count: undefined,
      until: today.clone().add(1, 'year').endOf('day').format('YYYY-MM-DDTHH:mm:ssZ'),
    })
  })
})
