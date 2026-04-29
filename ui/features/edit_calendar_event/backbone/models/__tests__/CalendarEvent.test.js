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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {waitFor} from '@canvas/test-utils/Waiters'

describe('Calendar', () => {
  describe('CalendarEvent', () => {
    describe('#fetch()', () => {
      let calendarEvent
      let requestCount = 0
      const server = setupServer()

      beforeAll(() => {
        server.listen()
      })

      beforeEach(() => {
        requestCount = 0
        server.use(
          http.get('/sections', ({request}) => {
            requestCount++
            const url = new URL(request.url)
            const page = url.searchParams.get('page') || '1'
            const headers =
              page === '1' ? {Link: '<http://example.com/sections?page=2>; rel="next"'} : {}
            return HttpResponse.json([], {headers})
          }),
        )

        calendarEvent = new CalendarEvent({sections_url: '/sections'})

        vi.spyOn(calendarEvent, 'showSpinner')
        vi.spyOn(calendarEvent, 'hideSpinner')
        vi.spyOn(calendarEvent, 'loadFailure')
      })

      afterEach(() => {
        server.resetHandlers()
      })

      afterAll(() => {
        server.close()
      })

      async function fetch() {
        calendarEvent.fetch()
        await waitFor(
          () =>
            calendarEvent.hideSpinner.mock.calls.length === 1 ||
            calendarEvent.loadFailure.mock.calls.length === 1,
        )
      }

      // Skip with LX-2093
      test.skip('requests all pages', async () => {
        await fetch()
        expect(requestCount).toBe(2)
      })

      // Fickle
      // Skip with LX-2093
      test.skip('hides spinner when all requests succeed', async () => {
        await fetch()
        expect(calendarEvent.hideSpinner.mock.calls).toHaveLength(1)
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
