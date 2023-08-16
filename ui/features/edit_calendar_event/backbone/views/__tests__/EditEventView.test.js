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
import _ from 'lodash'
import moment from 'moment-timezone'
import {fireEvent, within, getByText, waitFor} from '@testing-library/dom'
import CalendarEvent from '../../models/CalendarEvent'
import EditEventView from '../EditEventView'
import * as UpdateCalendarEventDialogModule from '@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog'

jest.mock('@canvas/rce/RichContentEditor')

const defaultTZ = 'Asia/Tokyo'

describe('EditEventView', () => {
  beforeAll(() => {
    moment.tz.setDefault(defaultTZ)
  })
  beforeEach(() => {
    window.ENV = {FEATURES: {}, TIMEZONE: 'Asia/Tokyo'}
    document.body.innerHTML = '<div id="application"><form id="content"></form></div>'
    jest
      .spyOn(UpdateCalendarEventDialogModule, 'renderUpdateCalendarEventDialog')
      .mockImplementation(() => Promise.resolve('all'))
  })

  afterEach(() => {
    window.ENV = null
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

  async function waitForRender() {
    let rendered
    const promise = new Promise(resolve => {
      rendered = resolve
    })
    _.defer(() => rendered())
    await promise
  }

  it('renders', () => {
    render()
    expect(within(document.body).getByText('Edit Calendar Event')).not.toBeNull()
  })

  it('defaults to today if no start date is given', () => {
    render({start_at: undefined})
    const today = Intl.DateTimeFormat('en', {
      timeZone: defaultTZ,
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    }).format(new Date())
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

    it('shows conferencing options when some conference types are enabled', () => {
      enableConferences()
      render()
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
      view.model.save = jest.fn(params => {
        expect(params.web_conference).toEqual(web_conference)
      })
      view.submit(null)
      expect(view.model.save).toHaveBeenCalled()
    })

    it('submits empty web_conference params when no current conference', () => {
      enableConferences()
      const view = render()
      view.model.save = jest.fn(params => {
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

    it('is shown in a k5 subject', () => {
      window.ENV.K5_SUBJECT_COURSE = true
      render()
      expect(
        within(document.body).getByLabelText('Mark as Important Date', {exact: false})
      ).toBeInTheDocument()
    })

    it('is shown in a k5 homeroom', () => {
      window.ENV.K5_HOMEROOM_COURSE = true
      render()
      expect(
        within(document.body).getByLabelText('Mark as Important Date', {exact: false})
      ).toBeInTheDocument()
    })

    it('is shown in a k5 account', () => {
      window.ENV.K5_ACCOUNT = true
      render()
      expect(
        within(document.body).getByLabelText('Mark as Important Date', {exact: false})
      ).toBeInTheDocument()
    })

    it('is shown and checked in a k5 subject with event already marked as important', () => {
      window.ENV.K5_SUBJECT_COURSE = true
      render({important_dates: true})
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
      window.ENV.FEATURES = {account_level_blackout_dates: false}
      render()
      expect(within(document.body).queryByText('Add to Course Pacing blackout dates')).toBeNull()
    })

    it('is shown when account level blackout dates are enabled', () => {
      window.ENV.FEATURES = {account_level_blackout_dates: true}
      render({context_type: 'course', course_pacing_enabled: 'true'})
      expect(
        within(document.body).getByLabelText('Add to Course Pacing blackout dates', {
          exact: false,
        })
      ).toBeInTheDocument()
    })

    it('erases and renders irrelevant fields when checked', () => {
      window.ENV.FEATURES = {account_level_blackout_dates: true}
      render({
        context_type: 'course',
        course_pacing_enabled: 'true',
        web_conference: {id: 1, conference_type: 'LtiConference', title: 'FooConf'},
      })
      const ids = [
        'more_options_start_time',
        'more_options_end_time',
        'calendar_event_location_name',
        'calendar_event_location_address',
        'calendar_event_conference_field',
      ]
      ids.forEach(id => expectEnabled(id))
      $('#calendar_event_blackout_date').attr('checked', true)
      $('#calendar_event_blackout_date').trigger('change')
      ids.forEach(id => expectDisabled(id))
      $('#calendar_event_blackout_date').attr('checked', false)
      $('#calendar_event_blackout_date').trigger('change')
      ids.forEach(id => expectEnabled(id))
    })
  })

  describe('recurring events', () => {
    beforeEach(() => {
      ENV.FEATURES = {calendar_series: true}
    })

    afterEach(() => {
      jest.restoreAllMocks()
    })

    it('displays the frequency picker', async () => {
      render()

      expect(within(document.body).getByText('Frequency:')).toBeVisible()
      expect(within(document.body).getByDisplayValue('Does not repeat')).toBeVisible()
    })

    it('hides the frequency picker when section dates are enabled', async () => {
      jest.spyOn($, 'ajaxJSON').mockImplementation((url, method, params, successCB) => {
        const sections = [{id: 1}]
        return Promise.resolve(sections).then(() => {
          successCB(sections, {getResponseHeader: () => ''})
        })
      })

      // jquery supplies this in the real app
      document.head.appendChild(document.createElement('style')).textContent =
        '.hidden {display: none; visibliity: hidden;}'

      render({sections_url: '/api/v1/courses/21/sections'})

      // await within(document.body).findAllByText('Use a different date for each section')
      const section_checkbox = await within(document.body).findByRole('checkbox', {
        id: 'use_section_dates', // name should work, but doesn't
      })
      expect(section_checkbox).toBeVisible()
      expect(within(document.body).getByText('Frequency:')).toBeVisible()
      expect(within(document.body).getByDisplayValue('Does not repeat')).toBeVisible()

      fireEvent.click(section_checkbox)
      expect(within(document.body).queryByText('Frequency:')).not.toBeVisible()
    })

    it('renders update calendar event dialog', async () => {
      const view = render({series_uuid: '123'})
      view.submit(null)

      await waitFor(() =>
        expect(
          UpdateCalendarEventDialogModule.renderUpdateCalendarEventDialog
        ).toHaveBeenCalledWith(expect.objectContaining(view.model.attributes))
      )
    })

    it('submits which params for recurring events', async () => {
      expect.assertions(1)
      const view = render({
        rrule: 'FREQ=DAILY;INTERVAL=1;COUNT=3',
        series_uuid: '123',
      })
      view.renderWhichEditDialog = jest.fn(() => Promise.resolve('all'))
      view.model.save = jest.fn(() => {
        expect(view.model.get('which')).toEqual('all')
      })
      view.submit(null)
      await waitFor(() => {
        if (view.model.get('which') !== 'all') throw new Error('which was not set')
      })
    })
  })
})
