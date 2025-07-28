/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import $ from 'jquery'
import moment from 'moment-timezone'
import {act, fireEvent, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {eventFormProps} from './mocks'
import CalendarEventDetailsForm from '../CalendarEventDetailsForm'
import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'
import * as UpdateCalendarEventDialogModule from '@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/calendar/jquery/CommonEvent/index')
jest.mock('@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog')

let defaultProps = eventFormProps()

const changeValue = (component, testid, value) => {
  const child = component.getByTestId(testid)
  expect(child).toBeInTheDocument()
  act(() => child.click())
  fireEvent.change(child, {target: {value}})
  act(() => child.blur())
  return child
}

const setTime = (component, testid, time) => {
  const clock = component.getByTestId(testid)
  act(() => clock.click())
  fireEvent.click(component.getByText(time))
  return clock
}

describe('CalendarEventDetailsForm', () => {
  beforeEach(() => {
    defaultProps = eventFormProps()
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
      startDate: () => moment(),
      endDate: () => moment(),
      allDay: () => false,
      multipleDates: () => false,
      calendarEvent: {
        important_dates: false,
        blackout_date: false,
      },
      save: jest.fn().mockResolvedValue({}),
    }))
    $.ajaxJSON = (_url, _method, _params, onSuccess, _onError) => {
      onSuccess([])
    }
    jest
      .spyOn(UpdateCalendarEventDialogModule, 'renderUpdateCalendarEventDialog')
      .mockImplementation(() => Promise.resolve('all'))
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
  })

  it('cannot have end time before start time', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    const start = setTime(component, 'event-form-start-time', '5:00 AM')
    setTime(component, 'event-form-end-time', '4:00 AM')

    const errMessage = component.getByText('End time cannot be before Start time')
    expect(errMessage).toBeInTheDocument()

    act(() => start.click())
    expect(errMessage).not.toBeInTheDocument()
  })

  it('cannot have start time after end time', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    const end = setTime(component, 'event-form-end-time', '2:00 AM')
    setTime(component, 'event-form-start-time', '2:30 AM')

    const errMessage = component.getByText('Start Time cannot be after End Time')
    expect(errMessage).toBeInTheDocument()

    act(() => end.click())
    expect(errMessage).not.toBeInTheDocument()
  })

  it('allows setting arbitrary start/ end times', async () => {
    const user = userEvent.setup({delay: null})
    const {getByTestId} = render(<CalendarEventDetailsForm {...defaultProps} />)
    const startInput = getByTestId('event-form-start-time')
    const endInput = getByTestId('event-form-end-time')
    await user.type(startInput, '8:14 AM')
    //this is necessary due to flaky insUI-jest interactions
    await userEvent.type(
      endInput,
      '{Backspace}{Backspace}{Backspace}{Backspace}{Backspace}{Backspace}{Backspace}{Backspace}9:38 AM{Enter}',
    )
    expect(startInput.value).toBe('8:14 AM')
    expect(endInput.value).toBe('9:38 AM')
  })

  it('cannot submit with an empty title', () => {
    const event = {...defaultProps.event, title: ''}
    const component = render(<CalendarEventDetailsForm {...defaultProps} event={event} />)
    expect(component.getByRole('button', {name: 'Submit'})).toBeDisabled()
    expect(component.queryByText('You must enter a title.')).not.toBeInTheDocument()
  })

  it('shows an error when user clears the title', () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)
    changeValue(component, 'edit-calendar-event-form-title', 'avocado')

    expect(component.getByRole('button', {name: 'Submit'})).toBeEnabled()

    changeValue(component, 'edit-calendar-event-form-title', '')

    expect(component.getByRole('button', {name: 'Submit'})).toBeDisabled()
    expect(component.getByText('You must enter a title.')).toBeInTheDocument()
  })

  it('autofills date when input was cleared', () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)
    changeValue(component, 'edit-calendar-event-form-date', '')
    fireEvent.blur(component.getByTestId('edit-calendar-event-form-date'))
    expect(component.getByTestId('edit-calendar-event-form-date').value).toMatch(
      /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat), (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{1,2}, \d{4}$/,
    )

    const errMessage = component.queryByText('This date is invalid.')
    expect(errMessage).not.toBeInTheDocument()
    expect(component.getByRole('button', {name: 'Submit'})).toBeEnabled()
  })

  it('does not show error with when choosing another date time format', async () => {
    const user = userEvent.setup({delay: null})
    jest.spyOn(window.navigator, 'language', 'get').mockReturnValue('en-AU')
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)
    await user.click(component.getByTestId('edit-calendar-event-form-date'))
    await user.click(component.getByTestId('edit-calendar-event-form-title'))
    expect(component.getByTestId('edit-calendar-event-form-date').value).toMatch(
      /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat), \d{1,2} (Jan|Feb|Mar|Apr|May|June|July|Aug|Sept|Oct|Nov|Dec) \d{4}$/,
    )

    const errMessage = component.queryByText('This date is invalid.')
    expect(errMessage).not.toBeInTheDocument()
    expect(component.getByRole('button', {name: 'Submit'})).toBeEnabled()
  })
})
