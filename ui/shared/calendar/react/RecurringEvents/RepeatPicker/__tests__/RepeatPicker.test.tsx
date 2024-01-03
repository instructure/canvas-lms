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
import {render, act, fireEvent, screen} from '@testing-library/react'
import moment from 'moment-timezone'
import RepeatPicker, {
  type RepeatPickerProps,
  getByMonthdateString,
  getLastWeekdayInMonthString,
} from '../RepeatPicker'
import type {UnknownSubset} from '../../types'
import {cardinalDayInMonth, weekdaysFromMoment} from '../../utils'

export function changeFreq(from: string, to: string): void {
  const freq = screen.getByDisplayValue(from)
  act(() => {
    fireEvent.click(freq)
  })
  const opt = screen.getByText(to)
  act(() => {
    fireEvent.click(opt)
  })
}

const defaultTZ = 'Asia/Tokyo'
const today = moment().tz(defaultTZ)

const defaultProps = (overrides: UnknownSubset<RepeatPickerProps> = {}): RepeatPickerProps => ({
  locale: 'en',
  timezone: defaultTZ,
  dtstart: today.toISOString(true).replace(/\.\d+Z/, ''),
  interval: 1,
  freq: 'DAILY',
  weekdays: undefined,
  pos: undefined,
  onChange: () => {},
  ...overrides,
})

describe('RepeatPicker', () => {
  beforeEach(() => {
    moment.tz.setDefault(defaultTZ)
  })

  describe('utilities', () => {
    it('getByMonthdateString returns the correct string', () => {
      expect(getByMonthdateString(moment('2023-07-03'), 'en', defaultTZ)).toEqual(
        'on the first Monday'
      )
      expect(getByMonthdateString(moment('2023-07-10'), 'en', defaultTZ)).toEqual(
        'on the second Monday'
      )
      expect(getByMonthdateString(moment('2023-07-17'), 'en', defaultTZ)).toEqual(
        'on the third Monday'
      )
      expect(getByMonthdateString(moment('2023-07-24'), 'en', defaultTZ)).toEqual(
        'on the fourth Monday'
      )
      expect(getByMonthdateString(moment('2023-07-31'), 'en', defaultTZ)).toEqual(
        'on the fifth Monday'
      )
    })

    it('getLastWeekdayInMonthString returns the formatted string', () => {
      expect(getLastWeekdayInMonthString('Fizzday')).toEqual('on the last Fizzday')
    })
  })

  describe('component', () => {
    it('renders daily', () => {
      const {getByDisplayValue, getByTestId, getByText} = render(
        <RepeatPicker {...defaultProps()} />
      )
      expect(getByText('Repeat every:')).toBeInTheDocument()
      expect(getByTestId('repeat-interval')).toBeInTheDocument()
      expect(getByTestId('repeat-frequency')).toBeInTheDocument()
      expect(getByDisplayValue('1')).toBeInTheDocument()
      expect(getByDisplayValue('Day')).toBeInTheDocument()
    })

    it('renders plural daily', () => {
      const {getByDisplayValue} = render(<RepeatPicker {...defaultProps({interval: 2})} />)
      expect(getByDisplayValue('2')).toBeInTheDocument()
      expect(getByDisplayValue('Days')).toBeInTheDocument()
    })

    it('renders weekly', () => {
      const {getByDisplayValue} = render(<RepeatPicker {...defaultProps({freq: 'WEEKLY'})} />)
      expect(getByDisplayValue('1')).toBeInTheDocument()
      expect(getByDisplayValue('Week')).toBeInTheDocument()
    })

    it('renders plural weeks', () => {
      const {getByDisplayValue} = render(
        <RepeatPicker {...defaultProps({interval: 2, freq: 'WEEKLY'})} />
      )
      expect(getByDisplayValue('2')).toBeInTheDocument()
      expect(getByDisplayValue('Weeks')).toBeInTheDocument()
    })

    // we can assume months and years do plural correctly too

    it('renders monthly by date', () => {
      const {getByDisplayValue} = render(<RepeatPicker {...defaultProps({freq: 'MONTHLY'})} />)
      expect(getByDisplayValue('1')).toBeInTheDocument()
      expect(getByDisplayValue('Month')).toBeInTheDocument()
      expect(getByDisplayValue(`on day ${today.date()}`)).toBeInTheDocument()
    })

    it('renders monthly by day', () => {
      const today_day = weekdaysFromMoment(today)
      const pos = cardinalDayInMonth(today).cardinal

      const {getByDisplayValue} = render(
        <RepeatPicker {...defaultProps({freq: 'MONTHLY', weekdays: today_day, pos})} />
      )
      expect(getByDisplayValue('1')).toBeInTheDocument()
      expect(getByDisplayValue('Month')).toBeInTheDocument()
      const which_day = getByMonthdateString(today, 'en', defaultTZ)
      expect(getByDisplayValue(which_day)).toBeInTheDocument()
    })

    it('renders monthly by the last day', () => {
      const {getByDisplayValue} = render(
        <RepeatPicker
          {...defaultProps({dtstart: '2023-06-30', freq: 'MONTHLY', weekdays: ['FR'], pos: -1})}
        />
      )
      expect(getByDisplayValue('1')).toBeInTheDocument()
      expect(getByDisplayValue('Month')).toBeInTheDocument()
      expect(getByDisplayValue('on the last Friday')).toBeInTheDocument()
    })

    it('renders monthly correctly when the last day is in the 4th week', () => {
      const {getByTestId, getByRole} = render(
        <RepeatPicker {...defaultProps({dtstart: '2023-07-25', freq: 'MONTHLY'})} />
      )
      fireEvent.click(getByTestId('repeat-month-mode'))
      expect(getByRole('option', {name: 'on day 25'})).toBeInTheDocument()
      expect(getByRole('option', {name: 'on the fourth Tuesday'})).toBeInTheDocument()
      expect(getByRole('option', {name: 'on the last Tuesday'})).toBeInTheDocument()
    })

    it('renders yearly by date', () => {
      const {getByDisplayValue, getByText} = render(
        <RepeatPicker {...defaultProps({freq: 'YEARLY'})} />
      )
      expect(getByDisplayValue('1')).toBeInTheDocument()
      expect(getByDisplayValue('Year')).toBeInTheDocument()
      expect(getByText(`on ${today.format('MMMM D')}`)).toBeInTheDocument()
    })

    it('calls onChange when interval changes', () => {
      const onChange = jest.fn()
      const {getByDisplayValue} = render(<RepeatPicker {...defaultProps({onChange})} />)
      const interval = getByDisplayValue('1')
      act(() => {
        const event = {target: {value: '2'}}
        fireEvent.change(interval, event)
      })
      expect(onChange).toHaveBeenCalledWith({
        interval: 2,
        freq: 'DAILY',
        weekdays: undefined,
        monthdate: undefined,
        month: undefined,
        pos: undefined,
      })
    })

    it('calls onChange when freq changes', async () => {
      const onChange = jest.fn()
      render(<RepeatPicker {...defaultProps({onChange})} />)
      changeFreq('Day', 'Week')
      expect(onChange).toHaveBeenCalledWith({
        interval: 1,
        freq: 'WEEKLY',
        weekdays: weekdaysFromMoment(today),
        monthdate: undefined,
        month: undefined,
        pos: undefined,
      })
    })

    it('calls onChange when weekdays changes', async () => {
      const onChange = jest.fn()
      const {getByDisplayValue} = render(
        <RepeatPicker {...defaultProps({freq: 'WEEKLY', onChange})} />
      )
      // get 2 weekdays in the correct order
      const weekdays = weekdaysFromMoment(today)
      let notTodayWeekday
      if (weekdays[0] === 'SU') {
        weekdays.push('MO')
        notTodayWeekday = 'MO'
      } else {
        weekdays.unshift('SU')
        notTodayWeekday = 'SU'
      }

      const weekday = getByDisplayValue(notTodayWeekday)
      act(() => {
        fireEvent.click(weekday)
      })
      expect(onChange).toHaveBeenCalledWith({
        interval: 1,
        freq: 'WEEKLY',
        weekdays,
        monthdate: undefined,
        month: undefined,
        pos: undefined,
      })
    })
  })
})
