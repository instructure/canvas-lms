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
import fakeENV from '@canvas/test-utils/fakeENV'
import subject from '../reports'
import Dispatcher from '../../dispatcher'
import config from '../../config'
import K from '../../constants'

const server = setupServer()

beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))
afterAll(() => server.close())

beforeEach(() => {
  fakeENV.setup()
  config.ajax = $.ajax
  config.quizReportsUrl = 'http://localhost/reports'
  subject.__reset__()
})

afterEach(() => {
  server.resetHandlers()
  subject.__reset__()
  fakeENV.teardown()
})

describe('quizReports:generate', function () {
  it('makes the right request', async () => {
    let capturedRequest = null

    server.use(
      http.post('http://localhost/reports', async ({request}) => {
        capturedRequest = {
          url: new URL(request.url).pathname,
          method: request.method,
          body: await request.json(),
        }
        return HttpResponse.json({
          quiz_reports: [
            {
              id: '200',
              url: 'http://localhost/reports/200',
              progress: {
                workflow_state: K.PROGRESS_ACTIVE,
                url: 'http://localhost/progress/123',
              },
            },
          ],
        })
      }),
      // Mock the progress URL that gets polled - keep it active so it doesn't
      // complete and alter the state during the test
      http.get('http://localhost/progress/*', () => {
        return HttpResponse.json({
          workflow_state: K.PROGRESS_ACTIVE,
          completion: 50,
        })
      }),
      // Mock any other report fetch requests
      http.get('http://localhost/reports*', () => {
        return HttpResponse.json({quiz_reports: []})
      }),
    )

    // Dispatch returns a promise that resolves when the POST succeeds
    await Dispatcher.dispatch('quizReports:generate', 'student_analysis')

    expect(capturedRequest).toBeTruthy()
    expect(capturedRequest.url).toBe('/reports')
    expect(capturedRequest.method).toBe('POST')
    expect(capturedRequest.body).toEqual({
      quiz_reports: [
        {
          report_type: 'student_analysis',
          includes_all_versions: true,
        },
      ],
      include: ['progress', 'file'],
    })

    expect(subject.getAll()[0].progress.workflowState).toBe(K.PROGRESS_ACTIVE)
  })
})
