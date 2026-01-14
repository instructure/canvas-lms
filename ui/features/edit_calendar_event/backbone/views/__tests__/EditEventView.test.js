/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import $ from 'jquery'
import '@canvas/backbone'
import moment from 'moment-timezone'
import {fireEvent, within, getByText, waitFor, screen} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import CalendarEvent from '../../models/CalendarEvent'
import EditEventView from '../EditEventView'
import * as UpdateCalendarEventDialogModule from '@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeENV from '@canvas/test-utils/fakeENV'
import deparam from 'deparam'

vi.mock('@canvas/rce/RichContentEditor')
vi.mock('@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog', () => ({
  renderUpdateCalendarEventDialog: vi.fn().mockImplementation(() => Promise.resolve('all')),
}))
vi.mock('deparam', () => ({
  default: vi.fn(() => ({})),
}))

const defaultTZ = 'Asia/Tokyo'
const server = setupServer(
  // Add default handler for the course API endpoint to resolve MSW warnings
  http.get('*/api/v1/courses/:courseId', ({params}) => {
    return HttpResponse.json({
      id: params.courseId,
      name: `Course ${params.courseId}`,
      course_code: `COURSE${params.courseId}`,
      workflow_state: 'available',
      term: {
        id: '1',
        name: 'Default Term',
      },
    })
  }),
)

describe('EditEventView', () => {
  beforeAll(() => {
    moment.tz.setDefault(defaultTZ)
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    fakeENV.setup({FEATURES: {}, TIMEZONE: 'Asia/Tokyo'})
    document.body.innerHTML = '<div id="application"><form id="content"></form></div>'
  })

  afterEach(() => {
    fakeENV.teardown()
    vi.clearAllMocks()
    server.resetHandlers()
    // Reset deparam to default behavior
    deparam.mockReturnValue({})
  })

  function render(overrides = {}) {
    const event = new CalendarEvent({
      id: 1,
      title: 'My Event',
      start_at: '2020-05-11T23:27:35.738Z',
      context_code: 'course_1',
      ...overrides,
    })
    event.sync = () => {}

    return new EditEventView({el: document.getElementById('content'), model: event})
  }

  // wait 2 event cycles.  Why? because EditEventView init calls its own render function,
  // and its render function makes use of lodash defer, which defers some of its initialization
  // for 2 additional event cycles.  TODO: rewrite EditEventView to be a react component
  async function waitForRender() {
    // first wait
    await new Promise(resolve => {
      setTimeout(resolve)
    })
    // second wait
    await new Promise(resolve => {
      setTimeout(resolve)
    })
  }

  it('renders', async () => {
    const e = render()
    await waitForRender()
    expect(within(document.body).getByText(`Edit ${e.model.get('title')}`)).not.toBeNull()
  })

  it('defaults to today if no start date is given', async () => {
    render({start_at: undefined})
    const today = Intl.DateTimeFormat('en', {
      timeZone: defaultTZ,
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    }).format(new Date())
    await waitForRender()
    expect(within(document.body).getByDisplayValue(today)).toBeInTheDocument()
  })

  describe('conferences', () => {
    const CONFERENCE_TYPES = [
      {name: 'Type1', type: 'type1', contexts: ['course_1']},
      {name: 'Type2', type: 'type2', contexts: ['course_2', 'course_3']},
    ]

    function enableConferences(conference_types = CONFERENCE_TYPES) {
      window.ENV.conferences = {conference_types}
    }

    it('does not show conferencing options when no conference types are enabled', async () => {
      render()
      await waitForRender()
      const conferencingNode = within(document.body).getByText('Conferencing:')
      expect(conferencingNode.closest('fieldset').className).toEqual('hide')
    })

    it('shows conferencing options when some conference types are enabled', async () => {
      enableConferences()
      render()
      await waitForRender()
      const conferencingNode = within(document.body).getByText('Conferencing:')
      expect(conferencingNode.closest('fieldset').className).not.toEqual('hide')
    })

    describe('when context does not support conferences', () => {
      it('does not show conferencing options when there is no current conference', async () => {
        enableConferences(CONFERENCE_TYPES.slice(1))
        render()
        await waitForRender()
        const conferencingRow = within(document.body).getByText('Conferencing:').closest('fieldset')
        expect(conferencingRow.className).toEqual('hide')
      })

      it('does show current conference when there is a current conference', async () => {
        enableConferences(CONFERENCE_TYPES.slice(1))
        render({web_conference: {id: 1, conference_type: 'LtiConference', title: 'FooConf'}})
        await waitForRender()
        const conferencingRow = within(document.body).getByText('Conferencing:').closest('fieldset')
        await waitForRender()
        expect(conferencingRow.className).not.toEqual('hide')
        expect(getByText(conferencingRow, 'FooConf')).not.toBeNull()
      })
    })

    it.skip('submits web_conference params for current conference', () => {
      // fix with VICE-3671
      enableConferences()
      const web_conference = {
        id: '1',
        name: 'Foo',
        conference_type: 'type1',
        lti_settings: {a: 1, b: 2, c: 3},
        title: 'My Event',
        user_settings: {
          scheduled_date: '2020-05-11T00:00:00.000Z',
        },
      }
      const view = render({
        web_conference,
      })
      view.model.save = vi.fn(params => {
        expect(params.web_conference).toEqual(web_conference)
      })
      view.submit(null)
      expect(view.model.save).toHaveBeenCalled()
    })

    it.skip('submits empty web_conference params when no current conference', async () => {
      enableConferences()
      const view = render()
      await waitForRender()
      view.model.save = vi.fn(params => {
        expect(params.web_conference).toEqual('')
      })
      view.submit(null)
      expect(view.model.save).toHaveBeenCalled()
    })
  })

  describe('important dates section', () => {
    it('is not shown in non-k5 contexts', () => {
      render()
      expect(within(document.body).queryByText('Mark as Important Date')).toBeNull()
    })

    it('is shown in a k5 subject', async () => {
      fakeENV.setup({FEATURES: {}, TIMEZONE: 'Asia/Tokyo', K5_SUBJECT_COURSE: true})
      render()
      await waitForRender()
      expect(
        within(document.body).getByLabelText('Mark as Important Date', {exact: false}),
      ).toBeInTheDocument()
    })

    it('is shown in a k5 homeroom', async () => {
      fakeENV.setup({FEATURES: {}, TIMEZONE: 'Asia/Tokyo', K5_HOMEROOM_COURSE: true})
      render()
      await waitForRender()
      expect(
        within(document.body).getByLabelText('Mark as Important Date', {exact: false}),
      ).toBeInTheDocument()
    })

    it('is shown in a k5 account', async () => {
      fakeENV.setup({FEATURES: {}, TIMEZONE: 'Asia/Tokyo', K5_ACCOUNT: true})
      render()
      await waitForRender()
      expect(
        within(document.body).getByLabelText('Mark as Important Date', {exact: false}),
      ).toBeInTheDocument()
    })

    it('is shown and checked in a k5 subject with event already marked as important', async () => {
      fakeENV.setup({FEATURES: {}, TIMEZONE: 'Asia/Tokyo', K5_SUBJECT_COURSE: true})
      render({important_dates: true})
      await waitForRender()
      const checkbox = within(document.body).getByLabelText('Mark as Important Date', {
        exact: false,
      })
      expect(checkbox).toBeInTheDocument()
      expect(checkbox).toHaveAttribute('checked')
    })
  })

  describe('blackout date checkbox', () => {
    const expectEnabled = id => {
      const element = within(document.body).queryByTestId(id)
      expect(element).toBeEnabled()
    }

    const expectDisabled = id => {
      const element = within(document.body).queryByTestId(id)
      expect(element).toBeDisabled()
    }

    it('is not shown when account level blackout dates are disabled', () => {
      fakeENV.setup({FEATURES: {account_level_blackout_dates: false}, TIMEZONE: 'Asia/Tokyo'})
      render()
      expect(within(document.body).queryByText('Add to Course Pacing blackout dates')).toBeNull()
    })

    it('is shown when account level blackout dates are enabled', async () => {
      fakeENV.setup({FEATURES: {account_level_blackout_dates: true}, TIMEZONE: 'Asia/Tokyo'})
      render({context_type: 'course', course_pacing_enabled: 'true'})
      await waitForRender()
      expect(
        within(document.body).getByLabelText('Add to Course Pacing blackout dates', {
          exact: false,
        }),
      ).toBeInTheDocument()
    })

    it('erases and renders irrelevant fields when checked', async () => {
      fakeENV.setup({FEATURES: {account_level_blackout_dates: true}, TIMEZONE: 'Asia/Tokyo'})
      render({
        context_type: 'course',
        course_pacing_enabled: 'true',
        web_conference: {id: 1, conference_type: 'LtiConference', title: 'FooConf'},
      })
      await waitForRender()
      const ids = [
        'more_options_start_time',
        'more_options_end_time',
        'calendar_event_location_name',
        'calendar_event_location_address',
        'calendar_event_conference_field',
      ]
      ids.forEach(id => expectEnabled(id))
      $('#calendar_event_blackout_date').prop('checked', true)
      $('#calendar_event_blackout_date').trigger('change')
      ids.forEach(id => expectDisabled(id))
      $('#calendar_event_blackout_date').prop('checked', false)
      $('#calendar_event_blackout_date').trigger('change')
      ids.forEach(id => expectEnabled(id))
    })
  })

  describe('recurring events', () => {
    afterEach(() => {
      vi.restoreAllMocks()
    })

    it('displays the frequency picker', async () => {
      render()
      await waitForRender()
      expect(within(document.body).getByTestId('frequency-picker')).toBeVisible()
      expect(within(document.body).getByDisplayValue('Does not repeat')).toBeVisible()
    })

    it('updates frequency picker values on date change', async () => {
      render()
      await waitForRender()
      let dateInput = within(document.body).getByPlaceholderText('Date')
      expect(dateInput).toHaveValue('May 12, 2020')
      let frequencyPicker = within(document.body).getByTestId('frequency-picker')
      fireEvent.click(frequencyPicker)

      expect(document.body.querySelector('#weekly-day')).toHaveTextContent('Weekly on Tuesday')
      expect(document.body.querySelector('#monthly-nth-day')).toHaveTextContent(
        'Monthly on the second Tuesday',
      )
      expect(document.body.querySelector('#annually')).toHaveTextContent('Annually on May 12')

      dateInput = within(document.body).getByPlaceholderText('Date')
      fireEvent.change(dateInput, {target: {value: 'April 12, 2001'}})
      frequencyPicker = within(document.body).getByTestId('frequency-picker')
      fireEvent.click(frequencyPicker)

      expect(document.body.querySelector('#weekly-day')).toHaveTextContent('Weekly on Thursday')
      expect(document.body.querySelector('#monthly-nth-day')).toHaveTextContent(
        'Monthly on the second Thursday',
      )
      expect(document.body.querySelector('#annually')).toHaveTextContent('Annually on April 12')
    })

    it('hides the frequency picker when section dates are enabled', async () => {
      const sections = [{id: 1}]
      server.use(
        http.get('*/api/v1/courses/21/sections', () => {
          return HttpResponse.json(sections, {
            headers: {
              'X-Response-Header': '',
            },
          })
        }),
      )

      // jquery supplies this in the real app
      document.head.appendChild(document.createElement('style')).textContent =
        '.hidden {display: none; visibliity: hidden;}'

      render({sections_url: '/api/v1/courses/21/sections'})
      await waitForRender()

      // await within(document.body).findAllByText('Use a different date for each section')
      const section_checkbox = await within(document.body).findByRole('checkbox', {
        id: 'use_section_dates', // name should work, but doesn't
      })
      expect(section_checkbox).toBeVisible()
      expect(within(document.body).getByTestId('frequency-picker')).toBeVisible()
      expect(within(document.body).getByDisplayValue('Does not repeat')).toBeVisible()

      fireEvent.click(section_checkbox)
      await waitForRender()
      expect(within(document.body).queryByTestId('frequency-picker')).not.toBeVisible()
    })

    it('shows the duplicates when section dates are enabled', async () => {
      const sections = [{id: 1}]
      server.use(http.get('/api/v1/courses/21/sections', () => HttpResponse.json(sections)))

      const event = new CalendarEvent({
        context_code: 'course_1',
        sections_url: '/api/v1/courses/21/sections',
      })
      event.sync = () => {}

      new EditEventView({el: document.getElementById('content'), model: event})

      const section_checkbox = await within(document.body).findByRole('checkbox', {
        id: 'use_section_dates',
      })
      expect(section_checkbox).toBeVisible()
      expect(document.getElementById('duplicate_event')).not.toBeVisible()

      await userEvent.click(section_checkbox)

      expect(document.getElementById('duplicate_event')).toBeVisible()
    })

    it.skip('renders update calendar event dialog', async () => {
      const view = render({series_uuid: '123', rrule: 'FREQ=WEEKLY;BYDAY=MO;INTERVAL=1;COUNT=5'})
      await waitForRender()
      view.submit(null)

      await waitFor(() =>
        expect(
          UpdateCalendarEventDialogModule.renderUpdateCalendarEventDialog,
        ).toHaveBeenCalledWith(expect.objectContaining(view.model.attributes)),
      )
    })

    it('does not render update calendar event dialog when saving a single event', async () => {
      render({series_uuid: null, rrule: null})
      await waitForRender()
      userEvent.click(await screen.findByText('Update Event'))

      await waitFor(() =>
        expect(
          UpdateCalendarEventDialogModule.renderUpdateCalendarEventDialog,
        ).not.toHaveBeenCalled(),
      )
    })

    it('does not render update calendar event dialog when changing series to a single event', async () => {
      render({series_uuid: '123', rrule: 'FREQ=WEEKLY;BYDAY=MO;INTERVAL=1;COUNT=5'})
      await waitForRender()
      userEvent.click(await screen.findByText('Frequency'))
      userEvent.click(await screen.findByText('Does not repeat'))
      userEvent.click(await screen.findByText('Update Event'))

      await waitFor(() =>
        expect(
          UpdateCalendarEventDialogModule.renderUpdateCalendarEventDialog,
        ).not.toHaveBeenCalled(),
      )
    })

    it.skip('submits which params for recurring events', async () => {
      expect.assertions(1)
      const view = render({
        rrule: 'FREQ=DAILY;INTERVAL=1;COUNT=3',
        series_uuid: '123',
      })
      await waitForRender()
      view.renderWhichEditDialog = vi.fn(() => Promise.resolve('all'))
      view.model.save = vi.fn(() => {
        expect(view.model.get('which')).toEqual('all')
      })
      view.submit(null)
      await waitFor(() => {
        if (view.model.get('which') !== 'all') throw new Error('which was not set')
      })
    })
  })

  describe('URL parameter handling for time fields', () => {
    it('skips URL param times when editing existing event', async () => {
      deparam.mockReturnValue({start_time: '3:00am', end_time: '4:00am'})

      const event = new CalendarEvent({
        id: 1,
        title: 'Existing Event',
        start_at: '2020-05-11T15:00:00.000Z', // 3:00 PM
        end_at: '2020-05-11T16:00:00.000Z', // 4:00 PM
        context_code: 'course_1',
      })
      event.sync = () => {}

      new EditEventView({el: document.getElementById('content'), model: event})
      await waitForRender()

      // Should NOT use URL params (3:00am), should use model times formatted correctly
      const startTimeInput = within(document.body).getByTestId('more_options_start_time')
      const endTimeInput = within(document.body).getByTestId('more_options_end_time')

      // The times should be empty (not set from URL params) and will be formatted by template
      expect(startTimeInput.value).not.toBe('3:00am')
      expect(endTimeInput.value).not.toBe('4:00am')
    })

    it('uses URL param times when creating new event', async () => {
      deparam.mockReturnValue({start_time: '3:00pm', end_time: '4:00pm'})

      const event = new CalendarEvent({
        title: 'New Event',
        context_code: 'course_1',
      })
      event.sync = () => {}

      new EditEventView({el: document.getElementById('content'), model: event})
      await waitForRender()

      // Should use URL params for new events
      const startTimeInput = within(document.body).getByTestId('more_options_start_time')
      const endTimeInput = within(document.body).getByTestId('more_options_end_time')

      expect(startTimeInput.value).toBe('3:00pm')
      expect(endTimeInput.value).toBe('4:00pm')
    })

    it('skips section-specific URL param times when editing existing event', async () => {
      deparam.mockReturnValue({
        start_time: '3:00am',
        end_time: '4:00am',
        start_date: 'May 12, 2020',
        calendar_event_context_code: 'course_section_123',
        course_sections: [{id: 123, name: 'Section 1'}],
      })

      const event = new CalendarEvent({
        id: 1,
        title: 'Existing Event',
        start_at: '2020-05-11T15:00:00.000Z', // 3:00 PM
        end_at: '2020-05-11T16:00:00.000Z', // 4:00 PM
        context_code: 'course_1',
      })
      event.sync = () => {}

      new EditEventView({el: document.getElementById('content'), model: event})
      await waitForRender()

      // Section-specific time inputs should NOT use URL params
      const sectionStartTimeInput = document.querySelector(
        'input[name="child_event_data[123][start_time]"]',
      )
      const sectionEndTimeInput = document.querySelector(
        'input[name="child_event_data[123][end_time]"]',
      )

      if (sectionStartTimeInput && sectionEndTimeInput) {
        expect(sectionStartTimeInput.value).not.toBe('3:00am')
        expect(sectionEndTimeInput.value).not.toBe('4:00am')
      }
    })

    it('uses section-specific URL param times when creating new event', async () => {
      deparam.mockReturnValue({
        start_time: '3:00pm',
        end_time: '4:00pm',
        start_date: 'May 12, 2020',
        calendar_event_context_code: 'course_section_123',
        course_sections: [{id: 123, name: 'Section 1'}],
      })

      const event = new CalendarEvent({
        title: 'New Event',
        context_code: 'course_1',
      })
      event.sync = () => {}

      new EditEventView({el: document.getElementById('content'), model: event})
      await waitForRender()

      // Section-specific time inputs SHOULD use URL params for new events
      const sectionStartTimeInput = document.querySelector(
        'input[name="child_event_data[123][start_time]"]',
      )
      const sectionEndTimeInput = document.querySelector(
        'input[name="child_event_data[123][end_time]"]',
      )

      if (sectionStartTimeInput && sectionEndTimeInput) {
        expect(sectionStartTimeInput.value).toBe('3:00pm')
        expect(sectionEndTimeInput.value).toBe('4:00pm')
      }
    })

    it('preserves other URL params when skipping time params', async () => {
      deparam.mockReturnValue({
        title: 'Test Event',
        start_time: '3:00am',
        end_time: '4:00am',
        location_name: 'Test Location',
      })

      const event = new CalendarEvent({
        id: 1,
        start_at: '2020-05-11T15:00:00.000Z',
        context_code: 'course_1',
      })
      event.sync = () => {}

      new EditEventView({el: document.getElementById('content'), model: event})
      await waitForRender()

      // Non-time URL params should still be applied
      const titleInput = document.getElementById('calendar_event_title')
      const locationInput = document.getElementById('calendar_event_location_name')

      expect(titleInput.value).toBe('Test Event')
      expect(locationInput.value).toBe('Test Location')
    })
  })
})
