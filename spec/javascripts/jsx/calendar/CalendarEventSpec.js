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

import CalendarEvent from 'ui/features/edit_calendar_event/backbone/models/CalendarEvent'
import FakeServer from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {waitFor} from '../support/Waiters'

QUnit.module('Calendar', () => {
  QUnit.module('CalendarEvent', () => {
    QUnit.module('#fetch()', hooks => {
      let calendarEvent
      let server

      hooks.beforeEach(() => {
        server = new FakeServer()

        server.for('/sections').respond([
          {status: 200, body: []},
          {status: 200, body: []},
        ])

        calendarEvent = new CalendarEvent({sections_url: '/sections'})

        sinon.stub(calendarEvent, 'showSpinner')
        sinon.stub(calendarEvent, 'hideSpinner')
        sinon.stub(calendarEvent, 'loadFailure')
      })

      hooks.afterEach(() => {
        server.teardown()
      })

      async function fetch() {
        calendarEvent.fetch()
        await waitFor(
          () =>
            calendarEvent.hideSpinner.callCount === 1 || calendarEvent.loadFailure.callCount === 1
        )
      }

      test('requests all pages', async () => {
        await fetch()
        const requests = server.filterRequests('/sections')
        strictEqual(requests.length, 2)
        requests.forEach(r => {
          ok(r.url.includes('include[]=permissions'))
        })
      })

      test('hides spinner when all requests succeed', async () => {
        await fetch()
        strictEqual(calendarEvent.hideSpinner.callCount, 1)
      })
    })

    QUnit.module('#url()', () => {
      test('url for a new event', () => {
        const calendarEvent = new CalendarEvent()
        strictEqual(calendarEvent.url(), '/api/v1/calendar_events/')
      })

      test('url for an existing event', () => {
        const calendarEvent = new CalendarEvent({id: 1})
        strictEqual(calendarEvent.url(), '/api/v1/calendar_events/1')
      })

      test('url for an existing event in a series', () => {
        const calendarEvent = new CalendarEvent({id: 1, which: 'all'})
        strictEqual(calendarEvent.url(), '/api/v1/calendar_events/1?which=all')
      })
    })
  })
})
