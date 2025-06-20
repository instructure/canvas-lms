/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import 'jquery-migrate'
import timezone from 'timezone'
import denver from 'timezone/America/Denver'
import newYork from 'timezone/America/New_York'
import SyllabusCollection from '../../collections/SyllabusCollection'
import SyllabusCalendarEventsCollection from '../../collections/SyllabusCalendarEventsCollection'
import SyllabusAppointmentGroupsCollection from '../../collections/SyllabusAppointmentGroupsCollection'
import SyllabusPlannerCollection from '../../collections/SyllabusPlannerCollection'
import SyllabusView from '../SyllabusView'
import SyllabusViewPrerendered from '@canvas/syllabus/SyllabusViewPrerendered'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.simulate'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'
import tzInTest from '@instructure/moment-utils/specHelpers'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

const setupServerResponses = () => {
  // Setup MSW handlers for different request types
  server.use(
    http.get('*', ({request}) => {
      const url = new URL(request.url)
      let response
      const links = `<${url.href}>; rel="first"`

      if (url.search.includes('type=assignment')) {
        response = SyllabusViewPrerendered.assignments
      } else if (url.search.includes('type=sub_assignment')) {
        response = SyllabusViewPrerendered.sub_assignments
      } else if (url.search.includes('type=event')) {
        response = SyllabusViewPrerendered.events
      } else if (url.pathname.includes('/api/v1/appointment_groups')) {
        response = SyllabusViewPrerendered.appointment_groups
      } else if (url.pathname.includes('/api/v1/planner/items')) {
        response = SyllabusViewPrerendered.planner_items
      }

      return HttpResponse.json(response, {
        headers: {
          Link: links,
        },
      })
    }),
  )
}

describe('SyllabusView', () => {
  let view

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())
  let fixtures
  let jumpToToday
  let miniMonth
  let syllabusContainer

  beforeEach(async () => {
    fakeENV.setup({TIMEZONE: 'America/Denver', CONTEXT_TIMEZONE: 'America/New_York'})
    setupServerResponses()

    tzInTest.configureAndRestoreLater({
      tz: timezone(denver, 'America/Denver'),
      tzData: {
        'America/Denver': denver,
        'America/New_York': newYork,
      },
      formats: getI18nFormats(),
    })

    jest.useFakeTimers().setSystemTime(new Date(2012, 0, 23, 15, 30))

    // Add pre-rendered html elements
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)

    jumpToToday = $(SyllabusViewPrerendered.jumpToToday)
    jumpToToday.appendTo(fixtures)

    miniMonth = $(SyllabusViewPrerendered.miniMonth())
    miniMonth.appendTo(fixtures)

    syllabusContainer = $(SyllabusViewPrerendered.syllabusContainer)
    syllabusContainer.appendTo(fixtures)

    // Fill the collections
    const collections = [
      new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'event'),
      new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'assignment'),
      new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'sub_assignment'),
      new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'reservable'),
      new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'manageable'),
      new SyllabusPlannerCollection([ENV.context_asset_string]),
    ]

    const collection = new SyllabusCollection(collections)

    // Wait for all collections to be fetched
    const fetchPromises = collections.map(col => {
      return new Promise((resolve, reject) => {
        col.fetch({
          data: {per_page: 50},
          success: resolve,
          error: reject,
        })
      })
    })

    await Promise.all(fetchPromises)

    // Render and bind behaviors
    view = new SyllabusView({
      el: '#syllabusTableBody',
      collection,
    })
  }, 30000) // Increase timeout to 30 seconds

  afterEach(() => {
    fakeENV.teardown()
    jest.useRealTimers()
    fixtures.remove()
    tzInTest.restore()
  })

  describe('rendering', () => {
    it('handles public course access correctly', async () => {
      view.can_read = true // public course -- can read
      view.is_valid_user = true // user - enrolled (can read)
      view.is_public_course = true
      view.can_participate = true
      view.render()

      // Check if links are rendered
      const $links = view.$el.find('a[href]')
      expect($links.length).toBeGreaterThan(0)
      $links.each((_, link) => {
        expect(link.href).toBeTruthy()
      })

      // Check for specific event types
      expect(view.$el.find('.syllabus_discussion_topic').length).toBeGreaterThan(0)
      expect(view.$el.find('.syllabus_wiki_page').length).toBeGreaterThan(0)
      expect(view.$el.find('.syllabus_event').length).toBeGreaterThan(0)
    }, 30000) // Increase timeout to 30 seconds

    it('handles non-public course access correctly', () => {
      view.can_read = false
      view.is_valid_user = false
      view.is_public_course = false
      view.can_participate = false
      view.render()

      // Check if syllabus is rendered without links
      const $links = view.$el.find('a[href]')
      expect($links).toHaveLength(0)
    })
  })

  describe('mini calendar', () => {
    beforeEach(() => {
      view.can_read = true
      view.is_valid_user = true
      view.is_public_course = true
      view.can_participate = true
    })

    it('highlights dates with events', () => {
      view.render()
      const dates = view.toJSON().dates
      const datesWithEvents = dates.filter(date => date.events && date.events.length > 0)
      expect(datesWithEvents.length).toBeGreaterThan(0)

      const $dates = $('.mini_calendar_day', miniMonth)
      const $hasEvents = $dates.filter(function () {
        // Extract date from the cell ID which is in format: mini_day_YYYY_MM_DD
        const [_, __, year, month, day] = $(this).attr('id').split('_')
        return datesWithEvents.some(eventDate => {
          if (!eventDate.date) return false
          return (
            eventDate.date.getDate() === parseInt(day, 10) &&
            eventDate.date.getMonth() + 1 === parseInt(month, 10) && // Month is 0-based in JS
            eventDate.date.getFullYear() === parseInt(year, 10)
          )
        })
      })
      expect($hasEvents.length).toBeGreaterThan(0)
    })

    it('shows event details on hover', () => {
      view.render()
      const $date = $('.mini_calendar_day', miniMonth).eq(5) // Pick a day in the middle of the month
      $date.simulate('mouseover')
      jest.advanceTimersByTime(100)
      expect($('[data-tooltip]').length).toBeGreaterThan(0)
    })

    it('updates main view when clicking a date', () => {
      view.render()
      const $date = $('.mini_calendar_day', miniMonth).eq(5) // Pick a day in the middle of the month
      $date.simulate('click')
      expect(view.$el.find('.date').length).toBeGreaterThan(0)
    })
  })
})
