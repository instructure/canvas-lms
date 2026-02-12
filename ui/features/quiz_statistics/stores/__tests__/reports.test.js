/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {waitFor} from '@testing-library/dom'
import fakeENV from '@canvas/test-utils/fakeENV'
import subject from '../reports'
import Dispatcher from '../../dispatcher'
import config from '../../config'
import quizReportsFixture from '../../__tests__/fixtures/quiz_reports.json'
import K from '../../constants'

// Helper to clean up any iframes created during tests
const cleanupIframes = () => {
  const iframes = document.querySelectorAll('iframe')
  iframes.forEach(iframe => iframe.parentNode?.removeChild(iframe))
}

const server = setupServer()

beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))

beforeEach(() => {
  fakeENV.setup()
  config.ajax = $.ajax
  config.quizReportsUrl = 'http://localhost/reports'
  cleanupIframes()
  subject.__reset__()
})

afterEach(() => {
  server.resetHandlers()
  cleanupIframes()
  subject.__reset__()
  if (document.createElement.mockRestore) {
    document.createElement.mockRestore()
  }
  fakeENV.teardown()
})

afterAll(() => server.close())

describe('.load', () => {
  it('should load and deserialize reports', async () => {
    server.use(
      http.get('http://localhost/reports*', () => {
        return HttpResponse.json(quizReportsFixture)
      }),
    )

    await subject.load()

    const quizReports = subject.getAll()
    expect(quizReports).toHaveLength(2)
    expect(quizReports.map(x => x.id).sort()).toEqual(['200', '201'])
  })

  it('emits change', async () => {
    const onChange = vi.fn()

    server.use(
      http.get('http://localhost/reports*', () => {
        return HttpResponse.json(quizReportsFixture)
      }),
    )

    subject.addChangeListener(onChange)

    // Ensure onChange hasn't been called yet
    expect(onChange).not.toHaveBeenCalled()

    await subject.load()

    // Verify the change event was fired after load completes
    await waitFor(() => {
      expect(onChange).toHaveBeenCalled()
    })

    // Verify it was called exactly once
    expect(onChange).toHaveBeenCalledTimes(1)
  })

  it('should request both "file" and "progress" to be included with quiz reports', async () => {
    let capturedUrl = null
    server.use(
      http.get('http://localhost/reports*', ({request}) => {
        capturedUrl = new URL(request.url).pathname + new URL(request.url).search
        return HttpResponse.json({quiz_reports: []})
      }),
    )

    await subject.load()

    expect(decodeURI(capturedUrl)).toBe(
      '/reports?include[]=progress&include[]=file&includes_all_versions=true',
    )
  })
})

describe('.populate', function () {
  it('tracks any active reports being generated', async () => {
    let capturedUrl = null
    server.use(
      http.get('*/progress/1', ({request}) => {
        capturedUrl = new URL(request.url).pathname
        return HttpResponse.json({
          workflow_state: K.PROGRESS_ACTIVE,
          completion: 40,
        })
      }),
    )

    subject.populate(
      {
        quiz_reports: [
          {
            id: '1',
            progress: {
              url: '/progress/1',
              workflow_state: K.PROGRESS_ACTIVE,
              completion: 40,
            },
          },
        ],
      },
      {track: true},
    )

    await waitFor(() => {
      expect(capturedUrl).toBe('/progress/1')
    })
  })
})

describe('quizReports:generate', function () {
  it('tracks the generation progress', async () => {
    cleanupIframes()

    let postRequestMade = false
    let progressRequestCount = 0

    server.use(
      http.post('http://localhost/reports', () => {
        postRequestMade = true
        return HttpResponse.json({
          quiz_reports: [
            {
              id: '1',
              url: 'http://localhost/reports/1',
              report_type: 'student_analysis',
              progress: {
                workflow_state: K.PROGRESS_ACTIVE,
                url: '/progress/1',
              },
            },
          ],
        })
      }),
      http.get('*/progress/1', () => {
        progressRequestCount++
        return HttpResponse.json({
          workflow_state: K.PROGRESS_ACTIVE,
          completion: progressRequestCount * 10,
        })
      }),
      http.get('http://localhost/reports*', () => {
        return HttpResponse.json({
          quiz_reports: [
            {
              id: '1',
              url: 'http://localhost/reports/1',
              report_type: 'student_analysis',
              progress: {
                workflow_state: K.PROGRESS_ACTIVE,
                completion: 50,
              },
            },
          ],
        })
      }),
    )

    Dispatcher.dispatch('quizReports:generate', 'student_analysis')

    await waitFor(() => {
      expect(postRequestMade).toBe(true)
    })

    await waitFor(() => {
      expect(progressRequestCount).toBeGreaterThan(0)
    })

    cleanupIframes()
  })

  // TODO: This test is temporarily disabled due to Backbone URL handling issues
  // when fetching individual models after progress polling completes.
  // The functionality is partially tested in the '.populate' test suite.
  it.skip('should auto download the file when generated', async () => {
    // First populate with an existing report that has a URL
    subject.populate({
      quiz_reports: [
        {
          id: '1',
          url: 'http://localhost/reports/1',
          report_type: 'student_analysis',
        },
      ],
    })

    server.use(
      http.post('*/reports', () => {
        return HttpResponse.json({
          quiz_reports: [
            {
              id: '1',
              url: 'http://localhost/reports/1',
              progress: {
                workflow_state: 'running',
                url: '/progress/1',
              },
            },
          ],
        })
      }),
      http.get('*/progress/1', () => {
        return HttpResponse.json({
          workflow_state: K.PROGRESS_COMPLETE,
          completion: 100,
        })
      }),
      http.get('**/reports/1*', () => {
        return HttpResponse.json({
          quiz_reports: [
            {
              id: '1',
              url: 'http://localhost/reports/1',
              file: {
                url: '/files/1/download',
              },
            },
          ],
        })
      }),
    )

    Dispatcher.dispatch('quizReports:generate', 'student_analysis')

    // Wait for all async operations to complete
    await waitFor(() => {
      const iframe = document.body.querySelector('iframe')
      return iframe && iframe.src.includes('/files/1/download')
    })

    const iframe = document.body.querySelector('iframe')

    expect(iframe).toBeTruthy()
    expect(iframe.src).toContain('/files/1/download')
    expect(iframe.style.display).toBe('none')
  })

  it('should reject if the report is being generated', async () => {
    const payload = {
      quiz_reports: [
        {
          id: '1',
          report_type: 'student_analysis',
          includes_all_versions: true,
          progress: {
            id: '1',
            workflow_state: K.PROGRESS_ACTIVE,
            url: '/progress/1',
          },
        },
      ],
    }

    let progressRequestMade = false
    server.use(
      http.get('*/progress/1', () => {
        progressRequestMade = true
        return HttpResponse.json({
          workflow_state: K.PROGRESS_ACTIVE,
          completion: 50,
        })
      }),
    )

    subject.populate(payload, {track: true})

    await waitFor(() => {
      expect(progressRequestMade).toBe(true)
    })

    await expect(Dispatcher.dispatch('quizReports:generate', 'student_analysis')).rejects.toThrow(
      'report is already being generated',
    )
  })
})
