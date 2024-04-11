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
import {act, fireEvent, getByTestId, render, waitFor} from '@testing-library/react'
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
  act(() => child.blur())
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
  const date = changeValue(component, 'edit-calendar-event-form-date', inputDate)
  expect(date.value).toBe('Thu, Jul 14, 2022')
  if (time) setTime(component, 'event-form-end-time', time)
  component.getByText('Submit').click()

  waitFor(() =>
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[start_at]': expectedDate,
      }),
      expect.any(Function),
      expect.any(Function)
    )
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
    expect.any(Function)
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
      jest.requireActual('@canvas/calendar/jquery/CommonEvent/index').default
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
      expect.any(Function)
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
        expect.any(Function)
      )
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
        expect.any(Function)
      )
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

    await waitFor(() =>
      expect(defaultProps.event.save).toHaveBeenCalledWith(
        expect.objectContaining({
          'calendar_event[start_at]': '2022-07-14T00:00:00.000Z',
        }),
        expect.any(Function),
        expect.any(Function)
      )
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
      '11:30 PM'
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
      '11:30 PM'
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
      '11:30 PM'
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
    await user.tripleClick(endInput)
    await user.type(endInput, '9:38 AM')
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
      /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat), (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{1,2}, \d{4}$/
    )

    const errMessage = component.queryByText('This date is invalid.')
    expect(errMessage).not.toBeInTheDocument()
    expect(component.getByRole('button', {name: 'Submit'})).toBeEnabled()
  })

  it('shows an error when user input is an invalid string', () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)
    changeValue(component, 'edit-calendar-event-form-date', 'avocado')
    // Work-around to raise blur event listener on date field
    component.getByTestId('edit-calendar-event-form-title').focus()

    expect(component.getByRole('button', {name: 'Submit'})).toBeDisabled()
    expect(component.getByText('This date is invalid.')).toBeInTheDocument()
    expect(component.getByTestId('edit-calendar-event-form-date')).toHaveValue('avocado')
  })

  it('does not show error with when choosing another date time format', async () => {
    const user = userEvent.setup({delay: null})
    jest.spyOn(window.navigator, 'language', 'get').mockReturnValue('en-AU')
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)
    await user.click(component.getByTestId('edit-calendar-event-form-date'))
    await user.click(component.getByTestId('edit-calendar-event-form-title'))
    expect(component.getByTestId('edit-calendar-event-form-date').value).toMatch(
      /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat), \d{1,2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{4}$/
    )

    const errMessage = component.queryByText('This date is invalid.')
    expect(errMessage).not.toBeInTheDocument()
    expect(component.getByRole('button', {name: 'Submit'})).toBeEnabled()
  })

  it('renders and updates an event with conferencing when it is available', async () => {
    defaultProps.event.webConference = conference
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    expect(component.getByText('Conferencing')).toBeInTheDocument()
    component.getByText('Submit').click()
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[web_conference][conference_type]': 'BigBlueButton',
        'calendar_event[web_conference][name]': 'BigBlueButton',
      }),
      expect.any(Function),
      expect.any(Function)
    )
  })

  it('can remove conferences when conferencing is available', async () => {
    defaultProps.event.webConference = conference
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    component.getByText('Remove conference: Conference').click()
    component.getByText('Submit').click()
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[web_conference]': '',
      }),
      expect.any(Function),
      expect.any(Function)
    )
  })

  it('renders and updates an event with important dates checkbox when context is a k5 subject', async () => {
    const event = defaultProps.event
    event.contextInfo.k5_course = true
    const component = render(<CalendarEventDetailsForm {...defaultProps} event={event} />)

    component.getByText('Mark as Important Date').click()
    component.getByText('Submit').click()
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[important_dates]': true,
      }),
      expect.any(Function),
      expect.any(Function)
    )
  })

  it('renders and updates an event with important dates checkbox when context is a k5 account', async () => {
    const event = defaultProps.event
    event.contextInfo.k5_account = true
    const component = render(<CalendarEventDetailsForm {...defaultProps} event={event} />)

    component.getByText('Mark as Important Date').click()
    component.getByText('Submit').click()
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[important_dates]': true,
      }),
      expect.any(Function),
      expect.any(Function)
    )
  })

  it('can create a blackout date event for a course with course pacing enabled', async () => {
    ENV.FEATURES.account_level_blackout_dates = true
    defaultProps.event.contextInfo = courseContext
    testBlackoutDateSuccess()
  })

  it('can create a blackout date event for an account with course pacing enabled', async () => {
    ENV.FEATURES.account_level_blackout_dates = true
    defaultProps.event.contextInfo = accountContext
    testBlackoutDateSuccess()
  })

  it('does not render blackout checkbox when the feature flag is off', async () => {
    ENV.FEATURES.account_level_blackout_dates = false
    defaultProps.event.contextInfo = courseContext
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    expect(
      component.queryByRole('checkbox', {name: 'Add to Course Pacing blackout dates'})
    ).not.toBeInTheDocument()
    defaultProps.event.contextInfo = userContext
  })

  it('does not render blackout checkbox in a user context', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    expect(
      component.queryByRole('checkbox', {name: 'Add to Course Pacing blackout dates'})
    ).not.toBeInTheDocument()
  })

  it('only enables relevant fields when blackout date checkbox is checked', async () => {
    ENV.FEATURES.account_level_blackout_dates = true
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    expectFieldsToBeEnabled(component, [
      'Title',
      'Location',
      'Date',
      'From',
      'To',
      'Calendar',
      'More Options',
      'Submit',
    ])

    component.getByText('Calendar').click()
    component.getByText('Geometry').click()
    component.getByText('Add to Course Pacing blackout dates').click()

    expectFieldsToBeEnabled(component, ['Title', 'Date', 'Calendar', 'More Options', 'Submit'])
    expectFieldsToBeDisabled(component, ['Location', 'From', 'To'])
  })

  it('does not render the location input for child (section) events', () => {
    const props = {...defaultProps}
    props.event.calendarEvent.parent_event_id = '133'
    const {getByText, queryByText} = render(<CalendarEventDetailsForm {...props} />)
    expect(getByText('Title')).toBeInTheDocument()
    expect(queryByText('Location')).not.toBeInTheDocument()
  })

  describe('frequency picker', () => {
    beforeEach(() => {
      defaultProps.event.isNewEvent = () => true
      commonEventFactory.mockImplementation(() => defaultProps.event)
    })

    afterEach(() => {
      defaultProps.event.isNewEvent = () => false
      jest.resetModules()
    })

    it('renders when creating', async () => {
      const component = render(<CalendarEventDetailsForm {...defaultProps} />)
      expect(component.queryByRole('combobox', {name: 'Frequency'})).toBeInTheDocument()
    })

    it('renders when editing', async () => {
      defaultProps.event.isNewEvent = () => false
      const component = render(<CalendarEventDetailsForm {...defaultProps} />)
      expect(component.queryByRole('combobox', {name: 'Frequency'})).toBeInTheDocument()
    })

    it('with option selected contains RRULE on submit', async () => {
      const component = render(<CalendarEventDetailsForm {...defaultProps} />)
      component.getByText('Frequency').click() // open the dropdown
      component.getByText('Daily').click() // select the option
      component.getByText('Submit').click()
      expect(defaultProps.closeCB).toHaveBeenCalled()
      expect(defaultProps.event.save).toHaveBeenCalledWith(
        expect.objectContaining({
          'calendar_event[rrule]': 'FREQ=DAILY;INTERVAL=1;COUNT=365',
        }),
        expect.any(Function),
        expect.any(Function)
      )
    })

    it('with not-repeat option selected does not contain RRULE on submit', async () => {
      const component = render(<CalendarEventDetailsForm {...defaultProps} />)
      component.getByText('Submit').click()

      expect(defaultProps.event.save).toHaveBeenCalledWith(
        expect.not.objectContaining({
          'calendar_event[rrule]': expect.anything(),
        }),
        expect.any(Function),
        expect.any(Function)
      )
    })

    it('with custom option selected opens the modal', async () => {
      const component = render(<CalendarEventDetailsForm {...defaultProps} />)
      component.getByText('Frequency').click()
      component.getByText('Custom...').click()
      const modal = await component.findByText('Custom Repeating Event')
      expect(modal).toBeInTheDocument()
    })

    it('does not reset when the date changes', async () => {
      const props = {...defaultProps}
      props.event = commonEventFactory(null, [userContext, courseContext])
      const nextDate = props.event.startDate().clone().add(1, 'day').format('ddd, MMM D, YYYY')

      const component = render(<CalendarEventDetailsForm {...props} />)
      component.getByText('Frequency').click()
      component.getByText('Daily').click()
      await waitFor(() => expect(component.queryByDisplayValue('Daily')).toBeInTheDocument())
      changeValue(component, 'edit-calendar-event-form-date', nextDate)
      expect(component.queryByDisplayValue('Daily')).toBeInTheDocument()
    })

    it('tracks day of week when the date changes', async () => {
      const props = {...defaultProps}
      props.event = commonEventFactory(null, [userContext, courseContext])
      const d = moment('2023-08-28') // a monday
      props.event.date = d.toDate()
      props.event.startDate = jest.fn(() => moment(props.event.date))
      const nextDate = d.clone().add(1, 'day').format('ddd, MMM D, YYYY')

      const component = render(<CalendarEventDetailsForm {...props} />)
      component.getByText('Frequency').click()
      screen.getByText('Weekly on Monday').click()
      await waitFor(() =>
        expect(component.queryByDisplayValue('Weekly on Monday')).toBeInTheDocument()
      )
      changeValue(component, 'edit-calendar-event-form-date', nextDate)
      expect(component.queryByDisplayValue('Weekly on Tuesday')).toBeInTheDocument()
    })

    it('does not change the custom frequency when the date changes', async () => {
      const props = {...defaultProps}
      props.event = commonEventFactory(null, [userContext, courseContext])
      const d = moment('2023-08-28') // a monday
      props.event.date = d.toDate()
      props.event.startDate = jest.fn(() => moment(props.event.date))
      props.event.object.rrule = 'FREQ=WEEKLY;BYDAY=MO;INTERVAL=1;COUNT=5'
      const nextDate = d.clone().add(1, 'day').format('ddd, MMM D, YYYY')

      const component = render(<CalendarEventDetailsForm {...props} />)
      expect(component.queryByDisplayValue('Weekly on Mon, 5 times')).toBeInTheDocument()

      changeValue(component, 'edit-calendar-event-form-date', nextDate)
      expect(component.queryByDisplayValue('Weekly on Mon, 5 times')).toBeInTheDocument()
    })
  })
})
