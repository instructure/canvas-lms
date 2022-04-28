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

import {within, fireEvent, getByText} from '@testing-library/dom'
import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'
import EditCalendarEventDetails from '../EditCalendarEventDetails'

const CONTEXTS = [
  {name: 'course1', asset_string: 'course_1', can_create_calendar_events: true, k5_course: false},
  {name: 'course2', asset_string: 'course_2', can_create_calendar_events: true, k5_course: true},
  {name: 'course3', asset_string: 'course_3', can_create_calendar_events: true, k5_course: false}
]

describe('EditCalendarEventDetails', () => {
  beforeEach(() => {
    window.ENV = {}
    document.body.innerHTML = '<div id="application"></div>'
  })

  afterEach(() => {
    window.ENV = null
  })

  function render(overrides = {}) {
    const event = commonEventFactory(
      {
        calendar_event: {
          id: 1,
          context_code: 'course_1',
          ...overrides
        }
      },
      CONTEXTS
    )
    event.allPossibleContexts = CONTEXTS

    return new EditCalendarEventDetails(
      '#application',
      event,
      Function.prototype,
      Function.prototype
    )
  }

  it('renders', () => {
    render()
    expect(within(document.body).getByText('Title:')).not.toBeNull()
  })

  describe('conferences', () => {
    const CONFERENCE_TYPES = [
      {name: 'Type1', type: 'type1', contexts: ['course_1']},
      {name: 'Type2', type: 'type2', contexts: ['course_2', 'course_3']}
    ]

    function enableConferences(conference_types = CONFERENCE_TYPES) {
      window.ENV.conferences = {conference_types}
    }

    it('does not show conferencing options when no conference types are enabled', async () => {
      render()
      const conferencingRow = await within(document.body).findByText('Conferencing:')
      expect(conferencingRow.closest('tr').className).toEqual('hide')
    })

    it('shows conferencing options when some conference types are enabled', () => {
      enableConferences()
      render()
      const conferencingNode = within(document.body).getByText('Conferencing:')
      expect(conferencingNode.closest('tr').className).not.toEqual('hide')
    })

    describe('when context does not support conferences', () => {
      it('does not show conferencing options when there is no current conference', async () => {
        enableConferences(CONFERENCE_TYPES.slice(1))
        render()
        const conferencingRow = await within(document.body).findByText('Conferencing:')
        expect(conferencingRow.closest('tr').className).toEqual('hide')
      })

      it('does show current conference when there is a current conference', async () => {
        enableConferences(CONFERENCE_TYPES.slice(1))
        render({web_conference: {id: 1, conference_type: 'LtiConference', title: 'FooConf'}})
        const conferencingRow = await within(document.body).findByText('Conferencing:')
        expect(conferencingRow.closest('tr').className).not.toEqual('hide')
        expect(getByText(conferencingRow.closest('tr'), 'FooConf')).not.toBeNull()
      })
    })

    describe('when event conference can be updated', () => {
      it('submits web_conference params for current conference', () => {
        enableConferences()
        const view = render()
        view.conference = {
          id: 1,
          name: 'Foo',
          conference_type: 'type1',
          lti_settings: {a: 1, b: 2, c: 3},
          title: 'Bar'
        }
        view.event.save = jest.fn(params => {
          ;[
            ['calendar_event[web_conference][id]', '1'],
            ['calendar_event[web_conference][name]', 'Foo'],
            ['calendar_event[web_conference][conference_type]', 'type1'],
            ['calendar_event[web_conference][lti_settings][a]', '1'],
            ['calendar_event[web_conference][lti_settings][b]', '2'],
            ['calendar_event[web_conference][lti_settings][c]', '3']
          ].forEach(([key, value]) => {
            expect(params[key]).toEqual(value)
          })
        })
        const submit = within(document.body).getByText('Submit')
        fireEvent.click(submit)
        expect(view.event.save).toHaveBeenCalled()
      })

      it('submits empty web_conference params when no current conference', () => {
        enableConferences()
        const view = render()
        view.conference = null
        view.event.save = jest.fn(params => {
          expect(params['calendar_event[web_conference]']).toEqual('')
        })
        const submit = within(document.body).getByText('Submit')
        fireEvent.click(submit)
        expect(view.event.save).toHaveBeenCalled()
      })
    })

    describe('when event conference cannot be updated', () => {
      it('does not show conferencing options when there is no current conference', async () => {
        enableConferences()
        render({parent_event_id: 1000})
        const conferencingRow = await within(document.body).findByText('Conferencing:')
        expect(conferencingRow.closest('tr').className).toEqual('hide')
      })

      it('does not submit web_conference params', () => {
        enableConferences()
        const view = render({parent_event_id: 1000})
        view.conference = null
        view.event.save = jest.fn(params => {
          expect(params['calendar_event[web_conference]']).toBeUndefined()
        })
        const submit = within(document.body).getByText('Submit')
        fireEvent.click(submit)
        expect(view.event.save).toHaveBeenCalled()
      })
    })

    describe('when an event is moved between contexts', () => {
      beforeEach(() => enableConferences())

      it('should remove the conference if it is not supported', () => {
        const view = render()
        const selectBox = within(document.body).getByLabelText('Calendar:')
        view.conference = {
          title: 'Conference',
          conference_type: 'type1'
        }
        fireEvent.change(selectBox, {target: {value: 'course_2'}})
        expect(view.conference).toBeNull()
      })

      it('should retain the conference if it is supported', () => {
        const view = render()
        const selectBox = within(document.body).getByLabelText('Calendar:')
        fireEvent.change(selectBox, {target: {value: 'course_2'}})
        view.conference = {
          title: 'Conference',
          conference_type: 'type2'
        }
        fireEvent.change(selectBox, {target: {value: 'course_3'}})
        expect(view.conference).not.toBeNull()
      })
    })
  })

  describe('important dates section', () => {
    it('is hidden by default', () => {
      render()
      expect(within(document.body).queryByText('Mark as Important Date')).not.toBeVisible()
    })

    it('appears when switching to k5 subject context', () => {
      render()
      const selectBox = within(document.body).getByLabelText('Calendar:')
      fireEvent.change(selectBox, {target: {value: 'course_2'}})
      expect(within(document.body).getByText('Mark as Important Date')).toBeInTheDocument()
      fireEvent.change(selectBox, {target: {value: 'course_1'}})
      expect(within(document.body).queryByText('Mark as Important Date')).not.toBeVisible()
    })

    it('submits important_dates param if checked', () => {
      const view = render()
      view.event.save = jest.fn(params => {
        expect(params['calendar_event[important_dates]']).toBeTruthy()
      })
      const selectBox = within(document.body).getByLabelText('Calendar:')
      fireEvent.change(selectBox, {target: {value: 'course_2'}})
      fireEvent.click(
        within(document.body).getByLabelText('Mark as Important Date', {exact: false})
      )
      fireEvent.click(within(document.body).getByText('Submit'))
      expect(view.event.save).toHaveBeenCalled()
    })

    it('does not submit important_dates param if not in k5 subject context', () => {
      const view = render()
      view.event.save = jest.fn(params => {
        expect(params['calendar_event[important_dates]']).toBeFalsy()
      })
      const selectBox = within(document.body).getByLabelText('Calendar:')
      fireEvent.change(selectBox, {target: {value: 'course_2'}})
      fireEvent.click(
        within(document.body).getByLabelText('Mark as Important Date', {exact: false})
      )
      fireEvent.change(selectBox, {target: {value: 'course_3'}})
      fireEvent.click(within(document.body).getByText('Submit'))
      expect(view.event.save).toHaveBeenCalled()
    })
  })
})
