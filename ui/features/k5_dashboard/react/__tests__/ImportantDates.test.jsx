/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import fetchMock from 'fetch-mock'
import moment from 'moment-timezone'
import {act, render, waitForElementToBeRemoved, waitFor} from '@testing-library/react'

import ImportantDates from '../ImportantDates'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'
import * as tz from '@canvas/datetime'
import {
  MOCK_ASSIGNMENTS,
  MOCK_EVENTS,
  MOCK_OBSERVEE_EVENTS,
  MOCK_OBSERVEE_ASSIGNMENTS,
  IMPORTANT_DATES_CONTEXTS,
} from '@canvas/k5/react/__tests__/fixtures'

const ASSIGNMENTS_URL = /\/api\/v1\/calendar_events\?type=assignment&important_dates=true&.*/
const EVENTS_URL = /\/api\/v1\/calendar_events\?type=event&important_dates=true&.*/

const OBSERVER_ASSIGNMENTS_URL =
  /\/api\/v1\/users\/5\/calendar_events\?type=assignment&important_dates=true&.*/
const OBSERVER_EVENTS_URL =
  /\/api\/v1\/users\/5\/calendar_events\?type=event&important_dates=true&.*/

describe('ImportantDates', () => {
  const currentUserId = '1'
  const getProps = (overrides = {}) => ({
    timeZone: 'UTC',
    contexts: IMPORTANT_DATES_CONTEXTS,
    selectedContextsLimit: 2,
    ...overrides,
  })

  beforeEach(() => {
    fetchMock.get(ASSIGNMENTS_URL, JSON.stringify(MOCK_ASSIGNMENTS))
    fetchMock.get(EVENTS_URL, JSON.stringify(MOCK_EVENTS))
  })

  afterEach(() => {
    fetchMock.restore()
    destroyContainer()
    localStorage.clear()
  })

  it('renders some loading skeletons only while loading', async () => {
    const {getAllByText, findByText, queryByText} = render(<ImportantDates {...getProps()} />)
    expect(getAllByText('Loading Important Date')[0]).toBeInTheDocument()
    expect(getAllByText('Loading Important Date Details')[0]).toBeInTheDocument()
    expect(await findByText('Math HW')).toBeInTheDocument()
    expect(queryByText('Loading Important Date')).not.toBeInTheDocument()
    expect(queryByText('Loading Important Date Details')).not.toBeInTheDocument()
  })

  it('shows an error message if assignments request fails', async () => {
    fetchMock.get(ASSIGNMENTS_URL, 500, {overwriteRoutes: true})
    const {findAllByText} = render(<ImportantDates {...getProps()} />)
    expect(
      (await findAllByText('Failed to load assignments in important dates.'))[0]
    ).toBeInTheDocument()
  })

  it('shows an error message if events request fails', async () => {
    fetchMock.get(EVENTS_URL, 500, {overwriteRoutes: true})
    const {findAllByText} = render(<ImportantDates {...getProps()} />)
    expect(
      (await findAllByText('Failed to load events in important dates.'))[0]
    ).toBeInTheDocument()
  })

  it('fires off requests with correct params', async () => {
    const {findByText} = render(<ImportantDates {...getProps()} />)
    await findByText('Math HW')
    const params = new URLSearchParams(fetchMock.lastUrl())
    expect(params.getAll('context_codes[]')).toEqual(['course_1', 'course_2'])
    expect(params.get('start_date')).toBe(moment().tz('UTC').startOf('day').toISOString())
    // Compare only the first half of the timestamp since the ms will differ slightly
    // from request call to assertion
    const expectedEndDate = moment().tz('UTC').add(2, 'years').toISOString()
    expect(params.get('end_date').split('T')[0]).toBe(expectedEndDate.split('T')[0])
    expect(params.get('per_page')).toBe('100')
  })

  it('renders a header for important dates', async () => {
    const {getByText, findByText} = render(<ImportantDates {...getProps()} />)
    await findByText('Math HW')
    expect(getByText('Important Dates')).toBeInTheDocument()
  })

  it('renders a panda empty state if there are no items to show', async () => {
    fetchMock.get(ASSIGNMENTS_URL, [], {overwriteRoutes: true})
    fetchMock.get(EVENTS_URL, [], {overwriteRoutes: true})
    const {findByText, getByTestId} = render(<ImportantDates {...getProps()} />)
    expect(await findByText('Waiting for important things to happen.')).toBeInTheDocument()
    expect(getByTestId('important-dates-panda')).toBeInTheDocument()
  })

  it('displays a timestamp for each date bucket', async () => {
    const assignments = MOCK_ASSIGNMENTS
    const date = moment().tz('UTC').endOf('day').toISOString()
    assignments[0].assignment.due_at = date
    fetchMock.get(ASSIGNMENTS_URL, assignments, {overwriteRoutes: true})
    const {findByText} = render(<ImportantDates {...getProps()} />)
    expect(await findByText(tz.format(date, 'date.formats.long_with_weekday'))).toBeInTheDocument()
  })

  it('includes a year in timestamp if date is not in the same year as now', async () => {
    const assignments = MOCK_ASSIGNMENTS
    assignments[0].assignment.due_at = '2150-07-02T00:00:00Z'
    fetchMock.get(ASSIGNMENTS_URL, assignments, {overwriteRoutes: true})
    const {findByText} = render(<ImportantDates {...getProps()} />)
    expect(await findByText('Thu Jul 2, 2150')).toBeInTheDocument()
  })

  it('shows the context names for each item', async () => {
    const {findByText, getAllByText} = render(<ImportantDates {...getProps()} />)
    expect(await findByText('Algebra 2')).toBeInTheDocument()
    const historyTitles = getAllByText('History')
    expect(historyTitles.length).toBe(3)
    historyTitles.forEach(t => {
      expect(t).toBeInTheDocument()
    })
  })

  it('shows the title and link for each item', async () => {
    const {findByText, getByText} = render(<ImportantDates {...getProps()} />)
    const yogaLink = await findByText('Morning Yoga')
    expect(yogaLink).toBeInTheDocument()
    expect(yogaLink.href).toBe(
      'http://localhost:3000/calendar?event_id=99&include_contexts=course_30'
    )
    const mathLink = getByText('Math HW')
    expect(mathLink).toBeInTheDocument()
    expect(mathLink.href).toBe('http://localhost:3000/courses/30/assignments/175')
  })

  it('shows close button if handleClose is provided', async () => {
    const handleCloseFunc = jest.fn()
    const {findByRole} = render(<ImportantDates {...getProps()} handleClose={handleCloseFunc} />)
    const closeButton = await findByRole('button', {name: 'Hide Important Dates'})
    expect(closeButton).toBeInTheDocument()
    act(() => closeButton.click())
    expect(handleCloseFunc).toHaveBeenCalledTimes(1)
  })

  it('does not show close button if handleClose is not provided', async () => {
    const {findByText, queryByText} = render(<ImportantDates {...getProps()} />)
    await findByText('Math HW')
    expect(queryByText('Hide Important Dates')).not.toBeInTheDocument()
  })

  it('allows a modal showing the selected calendars to be opened and closed', async () => {
    const {getByRole, findByText, queryByText} = render(
      <ImportantDates {...getProps({selectedContextCodes: ['course_3']})} />
    )
    const calendarsButton = getByRole('button', {
      name: 'Select calendars to retrieve important dates from',
    })
    expect(calendarsButton).not.toBeDisabled()

    act(() => calendarsButton.click())

    expect(await findByText('Calendars')).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'Economics 101', checked: false})).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'Home Room', checked: false})).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'The Maths', checked: true})).toBeInTheDocument()

    act(() => getByRole('button', {name: 'Cancel'}).click())

    await waitForElementToBeRemoved(() => queryByText('Calendars'))
  })

  it('defaults to the first <selectedContextsLimit> calendars when no selectedContextCodes are provided', async () => {
    const {getByRole, findByText} = render(<ImportantDates {...getProps()} />)

    act(() =>
      getByRole('button', {
        name: 'Select calendars to retrieve important dates from',
      }).click()
    )

    expect(await findByText('Calendars')).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'Economics 101', checked: true})).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'Home Room', checked: true})).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'The Maths', checked: false})).toBeInTheDocument()
  })

  it('also defaults when none of the selectedContextCodes are valid', async () => {
    const {getByRole, findByText} = render(
      <ImportantDates {...getProps()} selectedContextCodes={[]} />
    )

    act(() =>
      getByRole('button', {
        name: 'Select calendars to retrieve important dates from',
      }).click()
    )

    expect(await findByText('Calendars')).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'Economics 101', checked: true})).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'Home Room', checked: true})).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'The Maths', checked: false})).toBeInTheDocument()
  })

  it('does not show the calendar select modal if fewer contexts than the limit are provided', () => {
    const {queryByRole} = render(<ImportantDates {...getProps({selectedContextsLimit: 10})} />)
    expect(
      queryByRole('button', {name: 'Select calendars to retrieve important dates from'})
    ).not.toBeInTheDocument()
  })

  describe('Parent Support', () => {
    beforeEach(() => {
      global.ENV = {
        current_user_id: currentUserId,
      }
      fetchMock.get(OBSERVER_ASSIGNMENTS_URL, JSON.stringify(MOCK_OBSERVEE_ASSIGNMENTS))
      fetchMock.get(OBSERVER_EVENTS_URL, JSON.stringify(MOCK_OBSERVEE_EVENTS))
    })

    afterEach(() => {
      global.ENV = {}
    })

    it('requests observee calendar events when observing a student', async () => {
      const {getByText} = render(<ImportantDates {...getProps()} observedUserId="5" />)
      await waitFor(() => {
        expect(getByText('Number theory')).toBeInTheDocument()
        expect(getByText('Dynamics')).toBeInTheDocument()
        expect(getByText('First Quiz')).toBeInTheDocument()
      })
      expect(fetchMock.called(OBSERVER_ASSIGNMENTS_URL)).toBe(true)
      expect(fetchMock.called(OBSERVER_EVENTS_URL)).toBe(true)
    })

    it('doest not show the calendar select modal when observing a student', () => {
      const {queryByRole} = render(<ImportantDates {...getProps()} observedUserId="5" />)
      expect(
        queryByRole('button', {name: 'Select calendars to retrieve important dates from'})
      ).not.toBeInTheDocument()
    })

    it('shows the calendar select modal if the user is observing his own enrollments', () => {
      const {getByRole} = render(<ImportantDates {...getProps()} observedUserId={currentUserId} />)
      expect(
        getByRole('button', {name: 'Select calendars to retrieve important dates from'})
      ).toBeInTheDocument()
    })
  })
})
