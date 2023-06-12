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
import {act, fireEvent, render} from '@testing-library/react'
import {eventFormProps, conference, userContext, courseContext, accountContext} from './mocks'
import CalendarEventDetailsForm from '../CalendarEventDetailsForm'

let defaultProps = eventFormProps()

const changeValue = (component, role, name, value) => {
  const child = component.getByRole(role, {name})
  expect(child).toBeInTheDocument()
  act(() => child.click())
  fireEvent.change(child, {target: {value}})
  act(() => child.blur())
  return child
}

const setTime = (component, label, time) => {
  const clock = component.getByRole('combobox', {name: label})
  act(() => clock.click())
  fireEvent.click(component.getByText(time))
  return clock
}

const select = (component, role, name) => {
  const child = component.getByRole(role, {name})
  expect(child).toBeInTheDocument()
  act(() => child.click())
}

const testTimezone = (timezone, inputDate, expectedDate, time) => {
  defaultProps.timezone = timezone
  const component = render(<CalendarEventDetailsForm {...defaultProps} />)
  const date = changeValue(component, 'combobox', 'Date:', inputDate)
  expect(date.value).toBe('Thu, Jul 14, 2022')
  if (time) setTime(component, 'From:', time)
  select(component, 'button', 'Submit')

  expect(defaultProps.event.save).toHaveBeenCalledWith(
    expect.objectContaining({
      'calendar_event[start_at]': expectedDate,
    }),
    expect.anything(),
    expect.anything()
  )
}

const testBlackoutDateSuccess = () => {
  const component = render(<CalendarEventDetailsForm {...defaultProps} />)

  select(component, 'checkbox', 'Add to Course Pacing blackout dates')
  select(component, 'button', 'Submit')
  expect(defaultProps.event.save).toHaveBeenCalledWith(
    expect.objectContaining({
      'calendar_event[blackout_date]': true,
    }),
    expect.anything(),
    expect.anything()
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
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('creates a new event', async () => {
    defaultProps.event.isNewEvent = () => true
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)
    expect(defaultProps.setSetContextCB).toHaveBeenCalled()
    expect(defaultProps.contextChangeCB).toHaveBeenCalled()
    select(component, 'button', 'Submit')

    expect(defaultProps.closeCB).toHaveBeenCalled()
    // event.possibleContexts() is only called when a the event is new.
    expect(defaultProps.event.possibleContexts).toHaveBeenCalled()
    defaultProps.event.isNewEvent = () => false
  })

  it('renders main elements and updates an event with valid parameters', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    changeValue(component, 'textbox', 'Title:', 'Class Party')
    changeValue(component, 'textbox', 'Location:', 'The Zoo')
    changeValue(component, 'combobox', 'Date:', '2022-07-23T00:00:00.000Z')
    setTime(component, 'From:', '2:00 AM')
    setTime(component, 'To:', '3:00 PM')
    select(component, 'button', 'Calendar:')
    select(component, 'option', 'Geometry')
    expect(component.getByText('More Options')).toBeInTheDocument()
    select(component, 'button', 'Submit')

    expect(defaultProps.closeCB).toHaveBeenCalled()
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
      expect.anything(),
      expect.anything()
    )
  })

  it('can change the date multiple times', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    let date = changeValue(component, 'combobox', 'Date:', '2022-07-03T00:00:00.000Z')
    expect(date.value).toBe('Sun, Jul 3, 2022')
    date = changeValue(component, 'combobox', 'Date:', '2022-07-14T00:00:00.000Z')
    expect(date.value).toBe('Thu, Jul 14, 2022')
    date = changeValue(component, 'combobox', 'Date:', '2022-07-23T00:00:00.000Z')
    expect(date.value).toBe('Sat, Jul 23, 2022')
    select(component, 'button', 'Submit')

    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[start_at]': '2022-07-23T00:00:00.000Z',
      }),
      expect.anything(),
      expect.anything()
    )
  })

  it('can keep the same date when the date input is clicked and blurred', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    const date = changeValue(component, 'combobox', 'Date:', '2022-07-14T00:00:00.000Z')
    expect(date.value).toBe('Thu, Jul 14, 2022')

    for (let i = 0; i < 30; i++) {
      act(() => date.click())
      act(() => date.blur())
    }

    select(component, 'button', 'Submit')

    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[start_at]': '2022-07-14T00:00:00.000Z',
      }),
      expect.anything(),
      expect.anything()
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

    const start = setTime(component, 'From:', '5:00 AM')
    setTime(component, 'To:', '4:00 AM')

    const errMessage = component.getByText('End time cannot be before Start time')
    expect(errMessage).toBeInTheDocument()

    act(() => start.click())
    expect(errMessage).not.toBeInTheDocument()
  })

  it('cannot have start time after end time', async () => {
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    const end = setTime(component, 'To:', '2:00 AM')
    setTime(component, 'From:', '2:30 AM')

    const errMessage = component.getByText('Start Time cannot be after End Time')
    expect(errMessage).toBeInTheDocument()

    act(() => end.click())
    expect(errMessage).not.toBeInTheDocument()
  })

  it('renders and updates an event with conferencing when it is available', async () => {
    defaultProps.event.webConference = conference
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    expect(component.getByText('Conferencing:')).toBeInTheDocument()
    select(component, 'button', 'Submit')
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[web_conference][conference_type]': 'BigBlueButton',
        'calendar_event[web_conference][name]': 'BigBlueButton',
      }),
      expect.anything(),
      expect.anything()
    )
  })

  it('can remove conferences when conferencing is available', async () => {
    defaultProps.event.webConference = conference
    const component = render(<CalendarEventDetailsForm {...defaultProps} />)

    select(component, 'button', 'Remove conference: Conference')
    select(component, 'button', 'Submit')
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[web_conference]': '',
      }),
      expect.anything(),
      expect.anything()
    )
  })

  it('renders and updates an event with important dates checkbox when context is a k5 subject', async () => {
    const event = defaultProps.event
    event.contextInfo.k5_course = true
    const component = render(<CalendarEventDetailsForm {...defaultProps} event={event} />)

    select(component, 'checkbox', 'Mark as Important Date')
    select(component, 'button', 'Submit')
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[important_dates]': true,
      }),
      expect.anything(),
      expect.anything()
    )
  })

  it('renders and updates an event with important dates checkbox when context is a k5 account', async () => {
    const event = defaultProps.event
    event.contextInfo.k5_account = true
    const component = render(<CalendarEventDetailsForm {...defaultProps} event={event} />)

    select(component, 'checkbox', 'Mark as Important Date')
    select(component, 'button', 'Submit')
    expect(defaultProps.event.save).toHaveBeenCalledWith(
      expect.objectContaining({
        'calendar_event[important_dates]': true,
      }),
      expect.anything(),
      expect.anything()
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
      'Title:',
      'Location:',
      'Date:',
      'From:',
      'To:',
      'Calendar:',
      'More Options',
      'Submit',
    ])

    select(component, 'button', 'Calendar:')
    select(component, 'option', 'Geometry')
    select(component, 'checkbox', 'Add to Course Pacing blackout dates')

    expectFieldsToBeEnabled(component, ['Title:', 'Date:', 'Calendar:', 'More Options', 'Submit'])
    expectFieldsToBeDisabled(component, ['Location:', 'From:', 'To:'])
  })

  it('does not render the location input for child (section) events', () => {
    const props = {...defaultProps}
    props.event.calendarEvent.parent_event_id = '133'
    const {getByText, queryByText} = render(<CalendarEventDetailsForm {...props} />)
    expect(getByText('Title:')).toBeInTheDocument()
    expect(queryByText('Location:')).not.toBeInTheDocument()
  })
})
