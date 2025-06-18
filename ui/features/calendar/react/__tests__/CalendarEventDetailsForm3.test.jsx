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
import {eventFormProps, conference, userContext, courseContext, accountContext} from './mocks'
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
  if (testid == 'edit-calendar-event-form-date') {
    fireEvent.keyUp(child, {key: 'Enter', code: 'Enter'})
  } else {
    act(() => child.blur())
  }
  return child
}

const testBlackoutDateSuccess = async component => {
  const title = changeValue(component, 'edit-calendar-event-form-title', 'title')
  expect(title.value).toBe('title')

  const blackoutCheckbox = component.getByRole('checkbox', {
    name: 'Add to Course Pacing blackout dates',
  })
  expect(blackoutCheckbox).toBeInTheDocument()

  fireEvent.click(blackoutCheckbox)

  expect(blackoutCheckbox.checked).toBe(true)

  const submitButton = component.getByText('Submit')
  expect(submitButton).toBeInTheDocument()
  fireEvent.click(submitButton)

  await waitFor(() => {
    expect(defaultProps.event.save).toHaveBeenCalled()
  })
}

const expectFieldsToBeEnabled = (component, fieldNames) => {
  fieldNames.forEach(fieldName => {
    const field = component.getByTestId(`edit-calendar-event-form-${fieldName.toLowerCase()}`)
    expect(field).toBeEnabled()
  })
}

const expectFieldsToBeDisabled = (component, fieldNames) => {
  fieldNames.forEach(fieldName => {
    const field = component.getByTestId(`edit-calendar-event-form-${fieldName.toLowerCase()}`)
    expect(field).toBeDisabled()
  })
}

describe('CalendarEventDetailsForm', () => {
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
      const mockResponse = []
      setTimeout(() => onSuccess(mockResponse), 0)

      return {
        abort: jest.fn(),
        always: jest.fn(),
        catch: jest.fn(),
        done: jest.fn(),
        fail: jest.fn(),
        getAllResponseHeaders: jest.fn(),
        getResponseHeader: jest.fn(),
        overrideMimeType: jest.fn(),
        pipe: jest.fn(),
        progress: jest.fn(),
        promise: jest.fn(),
        readyState: 1,
        responseJSON: mockResponse,
        setRequestHeader: jest.fn(),
        state: jest.fn().mockReturnValue('resolved'),
        status: 200,
        statusCode: jest.fn(),
        statusText: 'OK',
        then: jest.fn(callback => {
          callback(mockResponse)
          return this
        }),
      }
    }
    jest
      .spyOn(UpdateCalendarEventDialogModule, 'renderUpdateCalendarEventDialog')
      .mockImplementation(() => Promise.resolve('all'))
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
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
      expect.any(Function),
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
      expect.any(Function),
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
      expect.any(Function),
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
      expect.any(Function),
    )
  })

  it('can create a blackout date event for a course with course pacing enabled', async () => {
    defaultProps.event.contextInfo = {...courseContext}

    // Use destructuring to get specific query methods from render
    const {getByTestId, getByRole, getByText} = render(
      <CalendarEventDetailsForm {...defaultProps} data-testid="calendar-event-form" />,
    )

    // Create component object with the same interface as the original test
    const component = {getByTestId, getByRole, getByText}

    // Run the test with our component wrapper
    await testBlackoutDateSuccess(component)
  })

  it('can create a blackout date event for an account with course pacing enabled', async () => {
    // Set up the context and ensure it's properly assigned before rendering
    defaultProps.event.contextInfo = {...accountContext}

    // Use destructuring to get specific query methods from render
    const {getByTestId, getByRole, getByText} = render(
      <CalendarEventDetailsForm {...defaultProps} data-testid="calendar-event-form" />,
    )

    // Create component object with the same interface as the original test
    const component = {getByTestId, getByRole, getByText}

    // Run the test with our component wrapper
    await testBlackoutDateSuccess(component)
  })

  it('does not render blackout checkbox when the feature flag is off', async () => {
    fakeENV.setup({
      FEATURES: {
        account_level_blackout_dates: false,
      },
    })
    defaultProps.event.contextInfo = courseContext
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    expect(
      component.queryByRole('checkbox', {name: 'Add to Course Pacing blackout dates'}),
    ).not.toBeInTheDocument()
    defaultProps.event.contextInfo = userContext
  })

  it('does not render blackout checkbox in a user context', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    expect(
      component.queryByRole('checkbox', {name: 'Add to Course Pacing blackout dates'}),
    ).not.toBeInTheDocument()
  })

  it('only enables relevant fields when blackout date checkbox is checked', async () => {
    // Create a fresh copy of props to avoid mutation issues
    const props = {
      ...eventFormProps(),
      event: {
        ...eventFormProps().event,
        contextInfo: {...courseContext, course_pacing_enabled: true},
        calendarEvent: {
          ...eventFormProps().event.calendarEvent,
          parent_event_id: null,
        },
      },
    }

    const component = render(<CalendarEventDetailsForm {...props} />)
    const blackoutCheckbox = component.getByRole('checkbox', {
      name: /Add to Course Pacing blackout dates/i,
    })
    expect(blackoutCheckbox).toBeInTheDocument()

    // Initially all fields should be enabled
    expectFieldsToBeEnabled(component, ['title', 'location'])

    // Check blackout date checkbox
    fireEvent.click(blackoutCheckbox)

    // Wait for state to update
    await waitFor(() => {
      expect(blackoutCheckbox).toBeChecked()
    })

    // Only title should be enabled, location should be disabled
    expectFieldsToBeEnabled(component, ['title'])
    expectFieldsToBeDisabled(component, ['location'])
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
        expect.any(Function),
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
      const nextDate = d.clone().add(1, 'day').toISOString()

      const component = render(<CalendarEventDetailsForm {...props} />)
      component.getByText('Frequency').click()
      component.getByText('Weekly on Monday').click()
      await waitFor(() =>
        expect(component.queryByDisplayValue('Weekly on Monday')).toBeInTheDocument(),
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
