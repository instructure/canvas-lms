/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {act, fireEvent, render, waitFor} from '@testing-library/react'
import {eventFormProps} from './mocks'
import CalendarEventDetailsForm from '../CalendarEventDetailsForm'
import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'
import * as UpdateCalendarEventDialogModule from '@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/calendar/jquery/CommonEvent/index')
jest.mock('@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog')

describe('CalendarEventDetailsForm frequency picker', () => {
  let defaultProps

  const changeValue = (component, testid, value) => {
    const child = component.getByTestId(testid)
    expect(child).toBeInTheDocument()
    act(() => child.click())
    fireEvent.change(child, {target: {value}})
    if (testid === 'edit-calendar-event-form-date') {
      fireEvent.keyUp(child, {key: 'Enter', code: 'Enter'})
    } else {
      act(() => child.blur())
    }
    return child
  }

  beforeEach(() => {
    defaultProps = eventFormProps()
    defaultProps.event.object.all_context_codes = 'course_2'
    defaultProps.event.object.context_code = 'course_2'

    fakeENV.setup({
      FEATURES: {
        calendar_series: true,
        account_level_blackout_dates: true,
        course_paces: true,
        k5_course_welcome_pages: true,
        important_dates: true,
      },
      TIMEZONE: 'America/Denver',
    })

    commonEventFactory.mockImplementation(() => ({
      possibleContexts: () => [],
      isNewEvent: () => false,
      startDate: () => new Date(),
      endDate: () => new Date(),
      allDay: () => false,
      multipleDates: () => false,
      calendarEvent: {
        important_dates: false,
        blackout_date: false,
      },
      save: jest.fn().mockResolvedValue({}),
    }))

    jest
      .spyOn(UpdateCalendarEventDialogModule, 'renderUpdateCalendarEventDialog')
      .mockImplementation(() => Promise.resolve('all'))
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
  })

  it('with not-repeat option selected does not contain RRULE on submit', async () => {
    const {getByTestId, getByText} = render(<CalendarEventDetailsForm {...defaultProps} />)

    const title = changeValue({getByTestId}, 'edit-calendar-event-form-title', 'title')
    expect(title.value).toBe('title')

    const frequencyPicker = getByTestId('frequency-picker')
    fireEvent.click(frequencyPicker)

    await waitFor(() => {
      expect(getByText('Does not repeat')).toBeInTheDocument()
    })

    fireEvent.click(getByText('Does not repeat'))

    fireEvent.click(getByText('Submit'))

    await waitFor(() => {
      expect(defaultProps.event.save).toHaveBeenCalled()
      expect(defaultProps.event.save.mock.calls[0][0]).not.toHaveProperty('calendar_event[rrule]')
    })
  })
})
