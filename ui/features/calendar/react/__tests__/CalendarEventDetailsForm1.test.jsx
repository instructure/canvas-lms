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
import {screen} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import {eventFormProps, conference, userContext, courseContext, accountContext} from './mocks'
import CalendarEventDetailsForm from '../CalendarEventDetailsForm'
import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'
import * as UpdateCalendarEventDialogModule from '@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog'

jest.mock('@canvas/calendar/jquery/CommonEvent/index')
jest.mock('@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog')

let defaultProps = eventFormProps()

const changeValue = (component, testid, value) => {
  const child = component.getByTestId(testid)
  expect(child).toBeInTheDocument()
  act(() => child.click())
  fireEvent.change(child, {target: {value}})
  if (testid == 'edit-calendar-event-form-date') {
    fireEvent.keyUp(child, {key: 'Enter', code: 'Enter'})
  } else {
    act(() => child.blur())
  }
  return child
}

const setTime = (component, testid, time) => {
  const clock = component.getByTestId(testid)
  act(() => clock.click())
  fireEvent.click(component.getByText(time))
  return clock
}

const testTimezone = async (timezone, inputDate, expectedDate, time) => {
  defaultProps.timezone = timezone
  const component = render(<CalendarEventDetailsForm {...defaultProps} />)
  // CanvasDateInput2 now stores values as an ISO8601 compliant string
  changeValue(component, 'edit-calendar-event-form-date', inputDate)
  if (time) setTime(component, 'event-form-end-time', time)
  component.getByText('Submit').click()

  waitFor(() =>
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[start_at]': expectedDate,
      }),
      expect.any(Function),
      expect.any(Function),
    ),
  )
  await waitFor(() => expect(defaultProps.closeCB).toHaveBeenCalled())
}

const testBlackoutDateSuccess = () => {
  const component = render(<CalendarEventDetailsForm {...defaultProps} />)

  component.getByText('Add to Course Pacing blackout dates').click()
  component.getByText('Submit').click()
  expect(defaultProps.event.save).toHaveBeenCalledWith(
    expect.objectContaining({
      'calendar_event[blackout_date]': true,
    }),
    expect.any(Function),
    expect.any(Function),
  )
  defaultProps.event.contextInfo = userContext
  defaultProps.event.blackout_date = false
}

const expectFieldsToBeEnabled = (component, fieldNames) => {
  fieldNames.forEach(fieldName => expect(component.getByText(fieldName)).toBeEnabled())
}

const expectFieldsToBeDisabled = (component, fieldNames) => {
  fieldNames.forEach(fieldName => expect(component.getByLabelText(fieldName)).toBeDisabled())
}

describe('CalendarEventDetailsForm', () => {
  beforeEach(() => {
    defaultProps = eventFormProps()
    commonEventFactory.mockImplementation(
      jest.requireActual('@canvas/calendar/jquery/CommonEvent/index').default,
    )
    $.ajaxJSON = (_url, _method, _params, onSuccess, _onError) => {
      onSuccess({})
    }
    jest
      .spyOn(UpdateCalendarEventDialogModule, 'renderUpdateCalendarEventDialog')
      .mockImplementation(() => Promise.resolve('all'))
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('creates a new event', async () => {
    defaultProps.event.isNewEvent = () => true
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)
    expect(defaultProps.setSetContextCB).toHaveBeenCalled()
    expect(defaultProps.contextChangeCB).toHaveBeenCalled()
    component.getByText('Submit').click()

    await waitFor(() => expect(defaultProps.closeCB).toHaveBeenCalled())

    // event.possibleContexts() is only called when a the event is new.
    expect(defaultProps.event.possibleContexts).toHaveBeenCalled()
    defaultProps.event.isNewEvent = () => false
  })

  it('renders main elements and updates an event with valid parameters (flaky)', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    changeValue(component, 'edit-calendar-event-form-title', 'Class Party')
    changeValue(component, 'edit-calendar-event-form-location', 'The Zoo')
    changeValue(component, 'edit-calendar-event-form-date', '2022-07-23T00:00:00.000Z')
    setTime(component, 'event-form-start-time', '2:00 AM')
    setTime(component, 'event-form-end-time', '3:00 PM')
    component.getByText('Calendar').click()
    component.getByText('Geometry').click()
    expect(component.getByText('More Options')).toBeInTheDocument()
    component.getByText('Submit').click()
    await waitFor(() => expect(defaultProps.closeCB).toHaveBeenCalled())
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[title]': 'Class Party',
        'calendar_event[start_at]': '2022-07-23T02:00:00.000Z',
        'calendar_event[end_at]': '2022-07-23T15:00:00.000Z',
        'calendar_event[location_name]': 'The Zoo',
        'calendar_event[web_conference]': '',
        'calendar_event[context_code]': 'course_1',
        'calendar_event[important_dates]': false,
        'calendar_event[blackout_date]': false,
      }),
      expect.any(Function),
      expect.any(Function),
    )
  })

  it('shows UpdateCalendarEventsDialog when saving a recurring event', async () => {
    const props = eventFormProps()
    props.event.calendarEvent = {
      ...props.event.calendarEvent,
      series_uuid: '123',
    }
    props.event.object = {rrule: 'FREQ=DAILY;INTERVAL=1;COUNT=3'}

    const component = render(<CalendarEventDetailsForm {...props} />)
    component.getByText('Submit').click()

    expect(UpdateCalendarEventDialogModule.renderUpdateCalendarEventDialog).toHaveBeenCalled()
    await waitFor(() =>
      expect(props.event.save).toHaveBeenCalledWith(
        expect.objectContaining({which: 'all'}),
        expect.any(Function),
        expect.any(Function),
      ),
    )
  })

  it('does not show UpdateCalendarEventsDialog when saving a single event', async () => {
    const props = eventFormProps()
    props.event.calendarEvent = {
      ...props.event.calendarEvent,
      series_uuid: null,
    }
    props.event.object = {rrule: null}

    const component = render(<CalendarEventDetailsForm {...props} />)
    component.getByText('Submit').click()

    expect(UpdateCalendarEventDialogModule.renderUpdateCalendarEventDialog).not.toHaveBeenCalled()
    await waitFor(() => expect(props.event.save).toHaveBeenCalled())
  })

  it('does not show UpdateCalendarEventsDialog when changing series to a single event', async () => {
    const props = eventFormProps()
    props.event.calendarEvent = {
      ...props.event.calendarEvent,
      series_uuid: '123',
    }
    props.event.object = {rrule: 'FREQ=DAILY;INTERVAL=1;COUNT=3'}

    const component = render(<CalendarEventDetailsForm {...props} />)
    component.getByText('Frequency').click() // open the dropdown
    component.getByText('Does not repeat').click() // select the option
    component.getByText('Submit').click()

    expect(UpdateCalendarEventDialogModule.renderUpdateCalendarEventDialog).not.toHaveBeenCalled()
    await waitFor(() => expect(props.event.save).toHaveBeenCalled())
  })

  it('can change the date multiple times', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    let date = changeValue(component, 'edit-calendar-event-form-date', '2022-07-03T00:00:00.000Z')
    expect(date.value).toBe('Sun, Jul 3, 2022')
    date = changeValue(component, 'edit-calendar-event-form-date', '2022-07-14T00:00:00.000Z')
    expect(date.value).toBe('Thu, Jul 14, 2022')
    date = changeValue(component, 'edit-calendar-event-form-date', '2022-07-23T00:00:00.000Z')
    expect(date.value).toBe('Sat, Jul 23, 2022')
    component.getByText('Submit').click()

    await waitFor(() =>
      expect(defaultProps.event.save).toHaveBeenCalledWith(
        expect.objectContaining({
          'calendar_event[start_at]': '2022-07-23T00:00:00.000Z',
        }),
        expect.any(Function),
        expect.any(Function),
      ),
    )
  })

  it('shows the date for the France locale', async () => {
    const old_locale = window.ENV.LOCALE
    window.ENV.LOCALE = 'fr'

    const props = {...defaultProps}
    props.event = commonEventFactory(null, [userContext, courseContext])
    const d = moment('2023-08-28') // a monday
    props.event.date = d.toDate()
    props.event.startDate = jest.fn(() => moment(props.event.date))

    const {getByTestId} = render(<CalendarEventDetailsForm {...props} />)
    const beginning_date = getByTestId('edit-calendar-event-form-date')

    expect(beginning_date.value).toBe('lun. 28 août 2023')
    window.ENV.LOCALE = old_locale
  })

  // LF-630 (08/23/2023)
  it.skip('can keep the same date when the date input is clicked and blurred', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    const date = changeValue(component, 'edit-calendar-event-form-date', '2022-07-14T00:00:00.000Z')
    expect(date.value).toBe('Thu, Jul 14, 2022')

    for (let i = 0; i < 30; i++) {
      act(() => date.click())
      act(() => date.blur())
    }

    component.getByText('Submit').click()
    expect(date.value).toBe('Thu, Jul 14, 2022')

    await waitFor(() =>
      expect(defaultProps.event.save).toHaveBeenCalledWith(
        expect.objectContaining({
          'calendar_event[start_at]': '2022-07-14T00:00:00.000Z',
        }),
        expect.any(Function),
        expect.any(Function),
      ),
    )
  })

  it('can change the date in Denver at 12:00 AM', async () => {
    testTimezone('America/Denver', '2022-07-14T06:00:00.000Z', '2022-07-14T06:00:00.000Z')
  })

  it('can change the date in Denver at 11:30 PM', async () => {
    testTimezone(
      'America/Denver',
      '2022-07-14T06:00:00.000Z',
      '2022-07-15T05:30:00.000Z',
      '11:30 PM',
    )
  })

  it('can change the date in Shanghai at 12:00 AM', async () => {
    testTimezone('Asia/Shanghai', '2022-07-13T16:00:00.000Z', '2022-07-13T16:00:00.000Z')
  })

  it('can change the date in Shanghai at 11:30 PM', async () => {
    testTimezone(
      'Asia/Shanghai',
      '2022-07-13T16:00:00.000Z',
      '2022-07-14T15:30:00.000Z',
      '11:30 PM',
    )
  })

  it('can change the date in Adelaide at 12:00 AM', async () => {
    testTimezone('Australia/Adelaide', '2022-07-13T14:30:00.000Z', '2022-07-13T14:30:00.000Z')
  })

  it('can change the date in Adelaide at 11:30 PM', async () => {
    testTimezone(
      'Australia/Adelaide',
      '2022-07-13T14:30:00.000Z',
      '2022-07-14T14:00:00.000Z',
      '11:30 PM',
    )
  })

  it('can change the date in Tokyo at 12:00 AM', async () => {
    testTimezone('Asia/Tokyo', '2022-07-13T15:00:00.000Z', '2022-07-13T15:00:00.000Z')
  })

  it('can change the date in Tokyo at 11:30 PM', async () => {
    testTimezone('Asia/Tokyo', '2022-07-13T15:00:00.000Z', '2022-07-14T14:30:00.000Z', '11:30 PM')
  })

  it('can change the date in the UK at 12:00 AM', async () => {
    testTimezone('Etc/UTC', '2022-07-14T00:00:00.000Z', '2022-07-14T00:00:00.000Z')
  })

  it('can change the date in the UK at 11:30 PM', async () => {
    testTimezone('Etc/UTC', '2022-07-14T00:00:00.000Z', '2022-07-14T23:30:00.000Z', '11:30 PM')
  })

  it('can change the date in eastern Brazil at 12:00 AM', async () => {
    testTimezone('Brazil/East', '2022-07-14T03:00:00.000Z', '2022-07-14T03:00:00.000Z')
  })

  it('can change the date in eastern Brazil at 11:30 PM', async () => {
    testTimezone('Brazil/East', '2022-07-14T03:00:00.000Z', '2022-07-15T02:30:00.000Z', '11:30 PM')
  })

  it('does not show FrequencyPicker when the event is section-specific', () => {
    defaultProps.event.object.all_context_codes = 'course_2'
    defaultProps.event.object.context_code = 'course_section_22'

    render(<CalendarEventDetailsForm {...defaultProps} />)

    const frequencyPicker = screen.queryByText('Frequency')
    expect(frequencyPicker).not.toBeInTheDocument()
  })

  it('show FrequencyPicker when the event is not section-specific', () => {
    defaultProps.event.object.all_context_codes = 'course_2'
    defaultProps.event.object.context_code = 'course_2'

    render(<CalendarEventDetailsForm {...defaultProps} />)

    const frequencyPicker = screen.queryByText('Frequency')
    expect(frequencyPicker).toBeInTheDocument()
  })
})
