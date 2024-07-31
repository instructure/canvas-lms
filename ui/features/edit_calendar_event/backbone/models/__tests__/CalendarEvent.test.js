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

import CalendarEvent from '../CalendarEvent'
import FakeServer from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {waitFor} from '@canvas/test-utils/Waiters'

describe('Calendar', () => {
  describe('CalendarEvent', () => {
    describe('#fetch()', () => {
      let calendarEvent
      let server

      beforeEach(() => {
        server = new FakeServer()

        server.for('/sections').respond([
          {status: 200, body: []},
          {status: 200, body: []},
        ])

        calendarEvent = new CalendarEvent({sections_url: '/sections'})

        jest.spyOn(calendarEvent, 'showSpinner')
        jest.spyOn(calendarEvent, 'hideSpinner')
        jest.spyOn(calendarEvent, 'loadFailure')
      })

      afterEach(() => {
        server.teardown()
      })

      async function fetch() {
        calendarEvent.fetch()
        await waitFor(
          () =>
            calendarEvent.hideSpinner.mock.calls.length === 1 ||
            calendarEvent.loadFailure.mock.calls.length === 1
        )
      }

      test('requests all pages', async () => {
        await fetch()
        const requests = server.filterRequests('/sections')
        expect(requests.length).toBe(2)
        requests.forEach(r => {
          expect(r.url).toContain('include[]=permissions')
        })
      })

      test('hides spinner when all requests succeed', async () => {
        await fetch()
        expect(calendarEvent.hideSpinner.mock.calls.length).toBe(1)
      })
    })

    describe('#url()', () => {
      test('url for a new event', () => {
        const calendarEvent = new CalendarEvent()
        expect(calendarEvent.url()).toBe('/api/v1/calendar_events/')
      })

      test('url for an existing event', () => {
        const calendarEvent = new CalendarEvent({id: 1})
        expect(calendarEvent.url()).toBe('/api/v1/calendar_events/1')
      })

      test('url for an existing event in a series', () => {
        const calendarEvent = new CalendarEvent({id: 1, which: 'all'})
        expect(calendarEvent.url()).toBe('/api/v1/calendar_events/1?which=all')
      })
    })
  })
})
