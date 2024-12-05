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
import {fireEvent, render} from '@testing-library/react'
import {ConfiguredDateInput} from '../ConfiguredDateInput'
import moment from 'moment-timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'
// @ts-ignore
import tz from 'timezone'
// @ts-ignore
import chicago from 'timezone/America/Chicago'
// @ts-ignore
import detroit from 'timezone/America/Detroit'

describe('ConfiguredDateInput', () => {
  const placeholder = 'Select a date (optional)'
  const renderLabelText = 'Start date'
  const renderScreenReaderLabelText = 'Select a new beginning date'

  it('renders correctly with initial date', () => {
    const {getByPlaceholderText, getByText} = render(
      <ConfiguredDateInput
        selectedDate="2024-01-01T00:00:00.000Z"
        onSelectedDateChange={() => {}}
        placeholder={placeholder}
        renderLabelText={renderLabelText}
        renderScreenReaderLabelText={renderScreenReaderLabelText}
      />
    )
    const input = getByPlaceholderText(placeholder) as HTMLInputElement
    expect(input).toBeInTheDocument()
    expect(input.value).toBe('Jan 1 at 12am')
    expect(getByText(renderLabelText)).toBeInTheDocument()
    expect(getByText(renderScreenReaderLabelText)).toBeInTheDocument()
  })

  it('calls onSelectedDateChange when a date is selected', () => {
    const handleDateChange = jest.fn()
    const {getByPlaceholderText, getByText} = render(
      <ConfiguredDateInput
        selectedDate="2024-01-05T00:00:00.000Z"
        onSelectedDateChange={handleDateChange}
        placeholder={placeholder}
        renderLabelText={renderLabelText}
        renderScreenReaderLabelText={renderScreenReaderLabelText}
      />
    )

    const input = getByPlaceholderText(placeholder) as HTMLInputElement
    fireEvent.click(input)
    const jan15Button = getByText('15').closest('button')
    if (!jan15Button) {
      throw new Error('Could not find date button for jan 15')
    }
    fireEvent.click(jan15Button)
    expect(handleDateChange).toHaveBeenCalledWith(new Date('2024-01-15'), 'pick')
  })

  it('renders with disabled', () => {
    const {getByDisplayValue} = render(
      <ConfiguredDateInput
        selectedDate="2024-01-01T00:00:00.000Z"
        onSelectedDateChange={() => {}}
        placeholder={placeholder}
        renderLabelText={renderLabelText}
        renderScreenReaderLabelText={renderScreenReaderLabelText}
        disabled={true}
      />
    )
    expect(getByDisplayValue('Jan 1 at 12am')).toBeDisabled()
  })

  it('renders error message', () => {
    const errorMessage = 'This is an error message'

    const {getByText} = render(
      <ConfiguredDateInput
        selectedDate="2024-01-01T00:00:00.000Z"
        onSelectedDateChange={() => {}}
        placeholder={placeholder}
        renderLabelText={renderLabelText}
        renderScreenReaderLabelText={renderScreenReaderLabelText}
        errorMessage={errorMessage}
      />
    )
    expect(getByText(errorMessage)).toBeInTheDocument()
  })

  describe('course and user timezone', () => {
    beforeEach(() => {
      moment.tz.setDefault('America/Denver')

      tzInTest.configureAndRestoreLater({
        tz: tz(detroit, 'America/Detroit', chicago, 'America/Chicago'),
        tzData: {
          'America/Chicago': chicago,
          'America/Detroit': detroit,
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
          selectedDate="2024-02-03T00:00:00.000Z"
          onSelectedDateChange={() => {}}
          placeholder={placeholder}
          renderLabelText={renderLabelText}
          renderScreenReaderLabelText={renderScreenReaderLabelText}
          courseTimeZone={courseTimeZone}
          userTimeZone={userTimeZone}
        />
      )
      expect(getByText(expectedCourseDateString)).toBeInTheDocument()
      expect(getByText(expectedUserDateString)).toBeInTheDocument()
    })

    it('not renders time zone data on same timezones', () => {
      const {queryByText} = render(
        <ConfiguredDateInput
          selectedDate="2024-02-03T00:00:00.000Z"
          onSelectedDateChange={() => {}}
          placeholder={placeholder}
          renderLabelText={renderLabelText}
          renderScreenReaderLabelText={renderScreenReaderLabelText}
          courseTimeZone={courseTimeZone}
          userTimeZone={courseTimeZone}
        />
      )
      expect(queryByText(expectedCourseDateString)).toBeNull()
      expect(queryByText(expectedUserDateString)).toBeNull()
    })

    it('not renders time zone data on missing timezones', () => {
      const {queryByText} = render(
        <ConfiguredDateInput
          selectedDate="2024-02-03T00:00:00.000Z"
          onSelectedDateChange={() => {}}
          placeholder={placeholder}
          renderLabelText={renderLabelText}
          renderScreenReaderLabelText={renderScreenReaderLabelText}
        />
      )
      expect(queryByText(expectedCourseDateString)).toBeNull()
      expect(queryByText(expectedUserDateString)).toBeNull()
    })
  })
})
