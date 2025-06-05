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
import subject from '../reports'
import Dispatcher from '../../dispatcher'
import config from '../../config'
import quizReportsFixture from '../../__tests__/fixtures/quiz_reports.json'
import K from '../../constants'

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

// Helper to clean up any iframes created during tests
const cleanupIframes = () => {
  const iframes = document.querySelectorAll('iframe')
  iframes.forEach(iframe => iframe.parentNode.removeChild(iframe))
}

const server = setupServer()

beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))
afterEach(() => {
  server.resetHandlers()
  cleanupIframes()
  subject.__reset__()
})
afterAll(() => server.close())

beforeEach(() => {
  config.ajax = $.ajax
  config.quizReportsUrl = 'http://localhost/reports'
  cleanupIframes()
})

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
    const onChange = jest.fn()

    server.use(
      http.get('http://localhost/reports*', () => {
        return HttpResponse.json(quizReportsFixture)
      }),
    )

    subject.addChangeListener(onChange)
    await subject.load()

    // Give time for change event to fire
    await sleep(1)

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

    await sleep(10) // Give time for the request to be made

    expect(capturedUrl).toBe('/progress/1')
  })

  it('but it does not auto-download them when generated', async () => {
    // Make sure no iframes exist before the test
    cleanupIframes()

    let progressRequestMade = false
    let reportRequestMade = false

    server.use(
      http.get('*/progress/1', () => {
        progressRequestMade = true
        return HttpResponse.json({
          workflow_state: K.PROGRESS_COMPLETE,
          completion: 100,
        })
      }),
      http.get('http://localhost/reports*', () => {
        reportRequestMade = true
        return HttpResponse.json({
          quiz_reports: [
            {
              id: '1',
              file: {
                url: '/files/1/download',
              },
            },
          ],
        })
      }),
    )

    subject.populate(
      {
        quiz_reports: [
          {
            id: '1',
            url: 'http://localhost/reports/1',
            progress: {
              url: '/progress/1',
              workflow_state: K.PROGRESS_ACTIVE,
              completion: 40,
            },
          },
        ],
      },
      {track: true}, // track: true but autoDownload defaults to false
    )

    // Wait for the tracking to complete
    await sleep(100)

    expect(progressRequestMade).toBe(true)
    expect(reportRequestMade).toBe(true)

    // Since autoDownload is false, no iframe should be created
    const iframes = document.body.querySelectorAll('iframe[src="/files/1/download"]')
    expect(iframes).toHaveLength(0)
  })

  it('does not track the same report multiple times simultaneously', async () => {
    let requestCount = 0

    server.use(
      http.get('*/foobar', () => {
        requestCount++
        return HttpResponse.json({
          workflow_state: K.PROGRESS_ACTIVE,
        })
      }),
    )

    // First populate should trigger a request
    subject.populate(
      {
        quiz_reports: [
          {
            id: '1',
            progress: {
              workflow_state: K.PROGRESS_ACTIVE,
              url: '/foobar',
            },
          },
        ],
      },
      {track: true},
    )

    await sleep(10)
    expect(requestCount).toBe(1)

    // Second populate with same report should not trigger another request
    subject.populate(
      {
        quiz_reports: [
          {
            id: '1',
            progress: {
              workflow_state: K.PROGRESS_ACTIVE,
              url: '/foobar',
            },
          },
        ],
      },
      {track: true},
    )

    await sleep(10)
    expect(requestCount).toBe(1) // Should still be 1
  })
})

describe('quizReports:generate', function () {
  it('makes the right request', done => {
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
              progress: {
                workflow_state: 'foobar',
              },
            },
          ],
        })
      }),
    )

    Dispatcher.dispatch('quizReports:generate', 'student_analysis')
      .then(() => {
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

        expect(subject.getAll()[0].progress.workflowState).toBe('foobar')
        done()
      })
      .catch(error => done(error))
  })

  it('tracks the generation progress', async () => {
    let postRequestMade = false
    let progressRequestMade = false

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
        progressRequestMade = true
        return HttpResponse.json({
          workflow_state: K.PROGRESS_ACTIVE,
          completion: 50,
        })
      }),
      // Handle the eventual fetch request that happens during progress tracking
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

    await sleep(50)

    expect(postRequestMade).toBe(true)
    expect(progressRequestMade).toBe(true)
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
    await sleep(300)

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
    await sleep(10)
    expect(progressRequestMade).toBe(true)

    // The dispatcher returns a promise, so we can check if it rejects
    try {
      await new Promise((resolve, reject) => {
        Dispatcher.dispatch('quizReports:generate', 'student_analysis').then(resolve).catch(reject)
      })
      // If we get here, the test should fail
      expect(true).toBe(false)
    } catch (error) {
      expect(error.message).toContain('report is already being generated')
    }
  })

  it('should reject if the report is already generated', async () => {
    subject.populate({
      quiz_reports: [
        {
          id: '1',
          report_type: 'student_analysis',
          file: {
            url: '/attachments/1',
          },
        },
      ],
    })

    // The dispatcher returns a promise, so we can check if it rejects
    try {
      await new Promise((resolve, reject) => {
        Dispatcher.dispatch('quizReports:generate', 'student_analysis').then(resolve).catch(reject)
      })
      // If we get here, the test should fail
      expect(true).toBe(false)
    } catch (error) {
      expect(error.message).toContain('report is already generated')
    }
  })
})
