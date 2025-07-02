/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import subject from '../reports'
import config from '../../config'
import K from '../../constants'

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

const server = setupServer()

beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))
afterEach(async () => {
  server.resetHandlers()
  // __reset__() will clear all callbacks
  subject.__reset__()
  // Give a moment for any pending async operations to settle
  await sleep(10)
})
afterAll(() => server.close())

beforeEach(() => {
  config.ajax = $.ajax
  config.quizReportsUrl = 'http://localhost/reports'
  // Ensure we start with a clean state
  subject.__reset__()
})

describe('.populate', function () {
  it('does not track the same report multiple times simultaneously', async () => {
    // Start with a clean state
    subject.__reset__()

    let progressRequestCount = 0

    server.use(
      // Handle progress polling requests - keep returning active state
      http.get('http://localhost/progress/123', () => {
        progressRequestCount++
        return HttpResponse.json({
          workflow_state: K.PROGRESS_ACTIVE,
          completion: 50,
        })
      }),
      // Handle the fetch request that happens after polling - return reports collection
      http.get('http://localhost/reports', () => {
        return HttpResponse.json({
          quiz_reports: [
            {
              id: '1',
              report_type: 'student_analysis',
              progress: {
                workflow_state: K.PROGRESS_ACTIVE,
                url: 'http://localhost/progress/123',
                completion: 50,
              },
            },
          ],
        })
      }),
    )

    // First populate should trigger polling
    subject.populate(
      {
        quiz_reports: [
          {
            id: '1',
            report_type: 'student_analysis',
            progress: {
              workflow_state: K.PROGRESS_ACTIVE,
              url: 'http://localhost/progress/123',
              completion: 50,
            },
          },
        ],
      },
      {track: true},
    )

    // Wait for polling to start
    await sleep(50)

    // Store the initial count
    const initialProgressCount = progressRequestCount
    expect(initialProgressCount).toBeGreaterThan(0)

    // Second populate with same report should not trigger new polling
    subject.populate(
      {
        quiz_reports: [
          {
            id: '1',
            report_type: 'student_analysis',
            progress: {
              workflow_state: K.PROGRESS_ACTIVE,
              url: 'http://localhost/progress/123',
              completion: 50,
            },
          },
        ],
      },
      {track: true},
    )

    // Give some time to see if any new polling starts
    await sleep(100)

    // Calculate how many additional requests were made after the second populate
    const additionalRequests = progressRequestCount - initialProgressCount

    // The key is that the second populate shouldn't start a new independent polling cycle
    // Some additional requests might happen from the existing polling, but there shouldn't
    // be a significant spike that would indicate duplicate tracking
    expect(additionalRequests).toBeLessThan(3) // Allow for 1-2 requests from existing polling
  })
})
