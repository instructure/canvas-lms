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

import '@canvas/backbone'
import _ from 'lodash'
import {within, getByText} from '@testing-library/dom'
import CalendarEvent from '../../models/CalendarEvent'
import EditEventView from '../EditEventView'

jest.mock('@canvas/rce/RichContentEditor')

describe('EditEventView', () => {
  beforeEach(() => {
    window.ENV = {}
    document.body.innerHTML = '<div id="application"><form id="content"></form></div>'
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
      ...overrides
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

    it('submits web_conference params for current conference', () => {
      enableConferences()
      const web_conference = {
        id: '1',
        name: 'Foo',
        conference_type: 'type1',
        lti_settings: {a: 1, b: 2, c: 3},
        title: 'My Event',
        user_settings: {
          scheduled_date: '2020-05-11T00:00:00.000Z'
        }
      }
      const view = render({
        web_conference
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
    beforeEach(() => {
      window.ENV.FEATURES = {
        important_dates: true
      }
    })

    it('is not shown in non-k5 contexts', () => {
      render()
      expect(within(document.body).queryByText('Mark as Important Date')).toBeNull()
    })

    it('is not shown if important_dates flag is off', () => {
      window.ENV.FEATURES = {}
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

    it('is shown and checked in a k5 subject with event already marked as important', () => {
      window.ENV.K5_SUBJECT_COURSE = true
      render({important_dates: true})
      const checkbox = within(document.body).getByLabelText('Mark as Important Date', {
        exact: false
      })
      expect(checkbox).toBeInTheDocument()
      expect(checkbox).toHaveAttribute('checked')
    })
  })
})
