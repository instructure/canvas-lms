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
import userEvent from '@testing-library/user-event'
import {ConfiguredDateInput} from '../ConfiguredDateInput'
import moment from 'moment-timezone'
import {configureAndRestoreLater} from '@instructure/moment-utils/specHelpers'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'
import tz from 'timezone'
import chicago from 'timezone/America/Chicago'
import detroit from 'timezone/America/Detroit'
// @ts-expect-error
import denver from 'timezone/America/Denver'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('ConfiguredDateInput', () => {
  const placeholder = 'Select a date (optional)'
  const renderLabelText = 'Start date'
  const renderScreenReaderLabelText = 'Select a new beginning date'
  const currentYear = new Date().getFullYear()

  beforeEach(() => {
    const timezone = 'America/Denver'
    moment.tz.setDefault(timezone)
    fakeENV.setup({
      TIMEZONE: timezone,
    })

    configureAndRestoreLater({
      tz: tz(detroit, 'America/Detroit', chicago, 'America/Chicago', denver, 'America/Denver'),
      tzData: {
        'America/Detroit': detroit,
        'America/Chicago': chicago,
        'America/Denver': denver,
      },
      formats: getI18nFormats(),
    })

    // Mock the current date to be January 1st of the current year at noon
    jest.useFakeTimers()
    jest.setSystemTime(new Date(`${currentYear}-01-01T07:00:00.000Z`)) // 12am Denver time
  })

  afterEach(() => {
    jest.useRealTimers()
    fakeENV.teardown()
  })

  it('renders correctly with initial date', () => {
    const {getByPlaceholderText, getByText} = render(
      <ConfiguredDateInput
        selectedDate={`${currentYear}-01-01T07:00:00.000Z`} // 12am Denver time
        onSelectedDateChange={() => {}}
        placeholder={placeholder}
        renderLabelText={renderLabelText}
        renderScreenReaderLabelText={renderScreenReaderLabelText}
        userTimeZone="America/Denver"
      />,
    )
    const input = getByPlaceholderText(placeholder)
    expect(input).toBeInTheDocument()
    if (!(input instanceof HTMLInputElement)) {
      throw new Error('Expected input to be an HTMLInputElement')
    }
    expect(input.value).toBe('Jan 1 at 12am')
    expect(getByText(renderLabelText)).toBeInTheDocument()
    expect(getByText(renderScreenReaderLabelText)).toBeInTheDocument()
  })

  it('calls onSelectedDateChange when a date is selected', async () => {
    const user = userEvent.setup({
      advanceTimers: jest.advanceTimersByTime,
    })
    const handleDateChange = jest.fn()
    const {getByPlaceholderText} = render(
      <ConfiguredDateInput
        selectedDate={`${currentYear}-01-05T00:00:00.000Z`}
        onSelectedDateChange={handleDateChange}
        placeholder={placeholder}
        renderLabelText={renderLabelText}
        renderScreenReaderLabelText={renderScreenReaderLabelText}
      />,
    )

    const input = getByPlaceholderText(placeholder)
    await user.click(input)
    await user.tab()
    await user.keyboard('[Space]') // Open the date picker
    const jan15Button = screen.getByText('15').closest('button')
    if (!jan15Button) {
      throw new Error('Could not find date button for jan 15')
    }
    await user.click(jan15Button)

    // When clicking Jan 15 in the date picker, we get midnight in Denver (07:00 UTC)
    const expectedDate = new Date(`${currentYear}-01-15T07:00:00.000Z`)
    expect(handleDateChange).toHaveBeenCalledWith(expectedDate, 'pick')
  })

  it('renders with disabled', () => {
    const {getByPlaceholderText} = render(
      <ConfiguredDateInput
        selectedDate={`${currentYear}-01-01T07:00:00.000Z`} // 12am Denver time
        onSelectedDateChange={() => {}}
        placeholder={placeholder}
        renderLabelText={renderLabelText}
        renderScreenReaderLabelText={renderScreenReaderLabelText}
        userTimeZone="America/Denver"
        disabled={true}
      />,
    )
    const input = getByPlaceholderText(placeholder)
    if (!(input instanceof HTMLInputElement)) {
      throw new Error('Expected input to be an HTMLInputElement')
    }
    expect(input).toBeDisabled()
    expect(input.value).toBe('Jan 1 at 12am')
  })

  it('renders error message', () => {
    const errorMessage = 'This is an error message'

    const {getByText} = render(
      <ConfiguredDateInput
        selectedDate={`${currentYear}-01-01T00:00:00.000Z`}
        onSelectedDateChange={() => {}}
        placeholder={placeholder}
        renderLabelText={renderLabelText}
        renderScreenReaderLabelText={renderScreenReaderLabelText}
        errorMessage={errorMessage}
      />,
    )
    expect(getByText(errorMessage)).toBeInTheDocument()
  })

  it('renders info message', () => {
    const infoMessage = 'This is an info message'

    const {getByText} = render(
      <ConfiguredDateInput
        selectedDate={`${currentYear}-01-01T00:00:00.000Z`}
        onSelectedDateChange={() => {}}
        placeholder={placeholder}
        renderLabelText={renderLabelText}
        renderScreenReaderLabelText={renderScreenReaderLabelText}
        infoMessage={infoMessage}
      />,
    )
    expect(getByText(infoMessage)).toBeInTheDocument()
  })

  describe('course and user timezone', () => {
    beforeEach(() => {
      const timezone = 'America/Denver'
      moment.tz.setDefault(timezone)
      fakeENV.setup({
        TIMEZONE: timezone,
      })

      configureAndRestoreLater({
        tz: tz(detroit, 'America/Detroit', chicago, 'America/Chicago'),
        tzData: {
          'America/Detroit': detroit,
          'America/Chicago': chicago,
        },
        formats: getI18nFormats(),
      })
    })
    const courseTimeZone = 'America/Detroit'
    const userTimeZone = 'America/Chicago'
    const expectedCourseDateString = 'Local: Feb 2 at 6pm'
    const expectedUserDateString = 'Course: Feb 2 at 7pm'

    it('renders time zone data on different timezones', () => {
      const {getByText} = render(
        <ConfiguredDateInput
          selectedDate={`${currentYear}-02-03T00:00:00.000Z`}
          onSelectedDateChange={() => {}}
          placeholder={placeholder}
          renderLabelText={renderLabelText}
          renderScreenReaderLabelText={renderScreenReaderLabelText}
          courseTimeZone={courseTimeZone}
          userTimeZone={userTimeZone}
        />,
      )
      expect(getByText(expectedCourseDateString)).toBeInTheDocument()
      expect(getByText(expectedUserDateString)).toBeInTheDocument()
    })

    it('not renders time zone data on same timezones', () => {
      const {queryByText} = render(
        <ConfiguredDateInput
          selectedDate={`${currentYear}-02-03T00:00:00.000Z`}
          onSelectedDateChange={() => {}}
          placeholder={placeholder}
          renderLabelText={renderLabelText}
          renderScreenReaderLabelText={renderScreenReaderLabelText}
          courseTimeZone={courseTimeZone}
          userTimeZone={courseTimeZone}
        />,
      )
      expect(queryByText(expectedCourseDateString)).toBeNull()
      expect(queryByText(expectedUserDateString)).toBeNull()
    })

    it('not renders time zone data on missing timezones', () => {
      const {queryByText} = render(
        <ConfiguredDateInput
          selectedDate={`${currentYear}-02-03T00:00:00.000Z`}
          onSelectedDateChange={() => {}}
          placeholder={placeholder}
          renderLabelText={renderLabelText}
          renderScreenReaderLabelText={renderScreenReaderLabelText}
        />,
      )
      expect(queryByText(expectedCourseDateString)).toBeNull()
      expect(queryByText(expectedUserDateString)).toBeNull()
    })
  })
})
