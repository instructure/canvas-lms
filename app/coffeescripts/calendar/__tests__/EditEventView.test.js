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

import 'Backbone'
import _ from 'lodash'
import {within, getByText} from '@testing-library/dom'
import CalendarEvent from '../CalendarEvent'
import EditEventView from '../EditEventView'

jest.mock('jsx/shared/rce/RichContentEditor')

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
      window.ENV.CALENDAR = {CONFERENCES_ENABLED: true}
      window.ENV.conferences = {conference_types}
    }

    it('does not show conferencing options when calendar conferences are disabled', () => {
      render()
      expect(within(document.body).queryByText('Conferencing:')).toBeNull()
    })

    it('shows conferencing options when calendar conferences are enabled', () => {
      enableConferences()
      render()
      const conferencingNode = within(document.body).getByText('Conferencing:')
      expect(conferencingNode.closest('tr').className).not.toEqual('hide')
    })

    describe('when context does not support conferences', () => {
      it('does not show conferencing options when there is no current conference', async () => {
        enableConferences(CONFERENCE_TYPES.slice(1))
        render()
        await waitForRender()
        const conferencingRow = within(document.body)
          .getByText('Conferencing:')
          .closest('tr')
        expect(conferencingRow.className).toEqual('hide')
      })

      it('does show current conference when there is a current conference', async () => {
        enableConferences(CONFERENCE_TYPES.slice(1))
        render({web_conference: {id: 1, conference_type: 'type1', title: 'FooConf'}})
        const conferencingRow = within(document.body)
          .getByText('Conferencing:')
          .closest('tr')
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
        lti_settings: {a: 1, b: 2, c: 3}
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

    it('does not submit web_conference params when conferencing is disabled', () => {
      const view = render()
      view.model.save = jest.fn(params => {
        expect(params.web_conference).toBeUndefined()
      })
      view.submit(null)
      expect(view.model.save).toHaveBeenCalled()
    })
  })
})
