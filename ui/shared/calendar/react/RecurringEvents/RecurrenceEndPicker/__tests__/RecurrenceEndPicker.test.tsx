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
import type {UnknownSubset, FrequencyValue} from '../../types'
import RecurrenceEndPicker, {
  type RecurrenceEndPickerProps,
  CountValidator,
  UntilValidator,
  type InstuiMessage,
  type ModeValues,
} from '../RecurrenceEndPicker'
import {MAX_COUNT} from '../../RRuleHelper'

const defaultTZ = 'Asia/Tokyo'
const today = moment().tz(defaultTZ)

type messageSpy = jest.SpyInstance<InstuiMessage[], []>

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
  freq: 'DAILY',
  interval: 1,
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
      until: newEndDate.endOf('day').format('YYYY-MM-DDTHH:mm:ssZ'),
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

  it('fires onChange with undefined pos if the count input is invalid', async () => {
    const onChange = jest.fn()
    const props = {...defaultProps({onChange, count: 5})}
    const {getByDisplayValue} = render(<RecurrenceEndPicker {...props} />)

    const countinput = getByDisplayValue('5')

    act(() => {
      fireEvent.change(countinput, {target: {value: ''}})
    })
    expect(onChange).toHaveBeenCalledWith({
      until: undefined,
      count: undefined,
    })

    act(() => {
      fireEvent.change(countinput, {target: {value: 'invalid'}})
    })
    expect(onChange).toHaveBeenCalledWith({
      until: undefined,
      count: undefined,
    })

    act(() => {
      fireEvent.change(countinput, {target: {value: '5.2'}})
    })
    expect(onChange).toHaveBeenCalledWith({
      until: undefined,
      count: undefined,
    })

    act(() => {
      fireEvent.change(countinput, {target: {value: '-1'}})
    })
    expect(onChange).toHaveBeenCalledWith({
      until: undefined,
      count: undefined,
    })

    act(() => {
      fireEvent.change(countinput, {target: {value: '401'}})
    })
    expect(onChange).toHaveBeenCalledWith({
      until: undefined,
      count: undefined,
    })
  })

  describe('CountValidator', () => {
    describe('isValidCount', () => {
      it('returns false for NaN', () => {
        expect(CountValidator.isValidCount(NaN, 'AFTER')).toBe(false)
      })

      it('returns false for numbers out of bounds', () => {
        expect(CountValidator.isValidCount(-1, 'AFTER')).toBe(false)
        expect(CountValidator.isValidCount(MAX_COUNT + 1, 'AFTER')).toBe(false)
      })

      it('returns false for non-integers', () => {
        expect(CountValidator.isValidCount(1.5, 'AFTER')).toBe(false)
      })

      it('returns true if the mode is "ON"', () => {
        expect(CountValidator.isValidCount(1, 'ON')).toBe(true)
        expect(CountValidator.isValidCount(NaN, 'ON')).toBe(true)
        expect(CountValidator.isValidCount(-1, 'ON')).toBe(true)
        expect(CountValidator.isValidCount(MAX_COUNT + 1, 'ON')).toBe(true)
        expect(CountValidator.isValidCount(1.5, 'ON')).toBe(true)
      })
    })

    describe('getCountMessage', () => {
      afterEach(() => {
        jest.resetAllMocks()
      })

      it('returns the hint count is undefined', () => {
        const hintSpy: messageSpy = jest.spyOn(CountValidator, 'hint')
        CountValidator.getCountMessage(undefined)
        expect(hintSpy).toHaveBeenCalled()
      })

      it('returns the invalidCount message if the count is NaN', () => {
        const invalidCountSpy: messageSpy = jest.spyOn(CountValidator, 'invalidCount')
        CountValidator.getCountMessage(NaN)
        expect(invalidCountSpy).toHaveBeenCalled()
      })

      it('returns the countTooSmall message if the count is too small', () => {
        const countTooSmallSpy: messageSpy = jest.spyOn(CountValidator, 'countTooSmall')
        CountValidator.getCountMessage(0)
        expect(countTooSmallSpy).toHaveBeenCalled()
      })

      it('returns the countTooLarge message if the count is too large', () => {
        const countTooLargeSpy: messageSpy = jest.spyOn(CountValidator, 'countTooLarge')
        CountValidator.getCountMessage(MAX_COUNT + 1)
        expect(countTooLargeSpy).toHaveBeenCalled()
      })

      it('returns the countNotWhole message if the count is not a whole number', () => {
        const countNotWholeSpy: messageSpy = jest.spyOn(CountValidator, 'countNotWhole')
        CountValidator.getCountMessage(1.5)
        expect(countNotWholeSpy).toHaveBeenCalled()
      })
    })
  })

  describe('UntilValidator', () => {
    describe('getUntilMessage', () => {
      type getUntilMessageArgs = [
        until: string | undefined,
        timezone: string,
        eventStart: string,
        mode: ModeValues,
        freq: FrequencyValue,
        interval: number,
        courseEndAt: string | undefined
      ]
      const defaultGetUntilMessageProps = (overrides = {}): getUntilMessageArgs => {
        const propObj = {
          until: undefined,
          timezone: defaultTZ,
          eventStart: '2023-07-13T13:00:00-04:00',
          mode: 'ON',
          freq: 'DAILY',
          interval: 1,
          courseEndAt: undefined,
          ...overrides,
        }
        return Object.values(propObj) as getUntilMessageArgs
      }

      afterEach(() => {
        jest.resetAllMocks()
      })

      it('returns the hint count end mode is "AFTER"', () => {
        const hintSpy: jest.SpyInstance<InstuiMessage[], [CourseEndAt: string | undefined]> =
          jest.spyOn(UntilValidator, 'hint')
        UntilValidator.getUntilMessage.apply(null, defaultGetUntilMessageProps({mode: 'AFTER'}))
        expect(hintSpy).toHaveBeenCalled()
      })

      it('returns the hint if until is undefined', () => {
        const hintSpy: jest.SpyInstance<InstuiMessage[], [CourseEndAt: string | undefined]> =
          jest.spyOn(UntilValidator, 'hint')
        UntilValidator.getUntilMessage.apply(null, defaultGetUntilMessageProps())
        expect(hintSpy).toHaveBeenCalled()
      })

      it('returns too soon message if until is before event start', () => {
        const tooSoonSpy: messageSpy = jest.spyOn(UntilValidator, 'tooSoon')
        UntilValidator.getUntilMessage.apply(
          null,
          defaultGetUntilMessageProps({
            eventStart: '2023-07-13T13:00:00-04:00',
            until: '2023-07-12T13:00:00-04:00',
          })
        )
        expect(tooSoonSpy).toHaveBeenCalled()
      })

      it('returns too many message if until is too far in the future', () => {
        const tooManySpy: messageSpy = jest.spyOn(UntilValidator, 'tooMany')
        UntilValidator.getUntilMessage.apply(
          null,
          defaultGetUntilMessageProps({
            eventStart: '2023-07-13T13:00:00-04:00',
            until: '2025-07-13T13:00:00-04:00',
          })
        )
        expect(tooManySpy).toHaveBeenCalled()
      })
    })
  })
})
