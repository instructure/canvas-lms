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
import subject from '../reports'
import Dispatcher from '../../dispatcher'
import config from '../../config'
import quizReportsFixture from '../../__tests__/fixtures/quiz_reports.json'
import K from '../../constants'
import sinon from 'sinon'
import assertChange from 'chai-assert-change'

let fakeServer

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))
const jsonResponse = (statusCode, payload) => [
  statusCode,
  {'Content-Type': 'application/json'},
  JSON.stringify(payload),
]

beforeEach(() => {
  fakeServer = sinon.useFakeServer()
  config.ajax = $.ajax
  config.quizReportsUrl = '/reports'
})

afterEach(() => {
  fakeServer.restore()
  fakeServer = null

  subject.__reset__()
})

describe('.load', () => {
  it('should load and deserialize reports', () => {
    fakeServer.respondWith('GET', /^\/reports/, jsonResponse(200, quizReportsFixture))
    fakeServer.autoRespond = true

    return subject.load().then(() => {
      const quizReports = subject.getAll()

      expect(quizReports.length).toEqual(2)
      expect(quizReports.map(x => x.id).sort()).toEqual(['200', '201'])
    })
  })

  it('emits change', () => {
    const clock = sinon.useFakeTimers()
    const onChange = jest.fn()

    fakeServer.respondWith('GET', /^\/reports/, jsonResponse(200, quizReportsFixture))

    subject.addChangeListener(onChange)
    subject.load()

    assertChange({
      fn: () => {
        fakeServer.respond()
        clock.tick(1)
      },
      of: () => onChange.mock.calls.length,
      by: 1,
    })
    clock.restore()
  })

  it('should request both "file" and "progress" to be included with quiz reports', function () {
    assertChange({
      fn: () => subject.load(),
      of: () => fakeServer.requests.length,
      from: 0,
      to: 1,
    })

    const quizReportsUrl = decodeURI(fakeServer.requests[0].url)

    expect(quizReportsUrl).toBe(
      '/reports?include[]=progress&include[]=file&includes_all_versions=true'
    )
  })
})

describe('.populate', function () {
  it('tracks any active reports being generated', function () {
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
      {track: true}
    )

    expect(fakeServer.requests.length).toBe(1)
    expect(fakeServer.requests[0].url).toBe('/progress/1')
  })

  it('but it does not auto-download them when generated', async () => {
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
      {track: true}
    )

    await sleep(1) // let Promise tick

    expect(fakeServer.requests.length).toBe(1)
    expect(fakeServer.requests[0].url).toBe('/progress/1')

    fakeServer.respond(
      fakeServer.requests[0],
      jsonResponse(200, {
        workflow_state: K.PROGRESS_COMPLETE,
        completion: 100,
      })
    )

    await sleep(1)

    expect(fakeServer.requests.length).toBe(2)
    expect(fakeServer.requests[1].url).toContain('/reports/1')

    fakeServer.requests[1].respond(
      ...jsonResponse(200, {
        quiz_reports: [
          {
            id: '1',
            file: {
              url: '/files/1/download',
            },
          },
        ],
      })
    )

    await sleep(1)

    expect(fakeServer.requests.length).toBe(2)

    expect(document.body.querySelector('iframe[src="/files/1/download"]')).toBeFalsy()
  })

  it('does not track the same report multiple times simultaneously', async function () {
    await assertChange({
      fn: async () => {
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
          {track: true}
        )

        await sleep(1)
      },
      of: () => fakeServer.requests.length,
      by: 1,
    })

    await assertChange({
      fn: async () => {
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
          {track: true}
        )

        await sleep(1)
      },
      of: () => fakeServer.requests.length,
      by: 0,
    })
  })
})

describe('quizReports:generate', function () {
  it('makes the right request', async () => {
    Dispatcher.dispatch('quizReports:generate', 'student_analysis')

    expect(fakeServer.requests.length).toBe(1)
    expect(fakeServer.requests[0].url).toBe('/reports')
    expect(fakeServer.requests[0].method).toBe('POST')
    expect(fakeServer.requests[0].requestBody).toEqual(
      JSON.stringify({
        quiz_reports: [
          {
            report_type: 'student_analysis',
            includes_all_versions: true,
          },
        ],
        include: ['progress', 'file'],
      })
    )

    fakeServer.requests[0].respond(
      ...jsonResponse(200, {
        quiz_reports: [
          {
            id: '200',
            progress: {
              workflow_state: 'foobar',
            },
          },
        ],
      })
    )

    await sleep(1)

    expect(subject.getAll()[0].progress.workflowState).toBe('foobar')
  })

  it('tracks the generation progress', async () => {
    Dispatcher.dispatch('quizReports:generate', 'student_analysis')

    expect(fakeServer.requests.length).toBe(1)
    expect(fakeServer.requests[0].url).toBe('/reports')

    fakeServer.requests[0].respond(
      ...jsonResponse(200, {
        quiz_reports: [
          {
            id: '1',
            progress: {
              workflow_state: K.PROGRESS_ACTIVE,
              url: '/progress/1',
            },
          },
        ],
      })
    )

    await sleep(1)

    expect(fakeServer.requests.length).toBe(2)
    expect(fakeServer.requests[1].url).toBe('/progress/1')
  })

  it('should auto download the file when generated', async () => {
    Dispatcher.dispatch('quizReports:generate', 'student_analysis')

    expect(fakeServer.requests.length).toBe(1)
    expect(fakeServer.requests[0].url).toBe('/reports')

    fakeServer.requests[0].respond(
      ...jsonResponse(200, {
        quiz_reports: [
          {
            id: '1',
            progress: {
              workflow_state: 'running',
              url: '/progress/1',
            },
          },
        ],
      })
    )

    await sleep(1)

    expect(fakeServer.requests.length).toBe(2)
    expect(fakeServer.requests[1].url).toBe('/progress/1')

    fakeServer.requests[1].respond(
      ...jsonResponse(200, {
        workflow_state: K.PROGRESS_COMPLETE,
        completion: 100,
      })
    )

    await sleep(1)

    expect(fakeServer.requests.length).toBe(3)
    expect(fakeServer.requests[2].url).toContain('/reports/1?include%5B%5D=progress')

    fakeServer.requests[2].respond(
      ...jsonResponse(200, {
        quiz_reports: [
          {
            id: '1',
            file: {
              url: '/files/1/download',
            },
          },
        ],
      })
    )

    await sleep(1)

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

    assertChange({
      fn: () => subject.populate(payload, {track: true}),
      of: () => fakeServer.requests.length,
      by: 1,
    })

    return assertChange({
      fn: () => Dispatcher.dispatch('quizReports:generate', 'student_analysis'),
      of: () => fakeServer.requests.length,
      by: 0,
    }).then(
      () => {
        throw new Error('should not resolve!')
      },
      error => {
        expect(error.message).toContain('report is already being generated')
      }
    )
  })

  it('should reject if the report is already generated', function () {
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

    return assertChange({
      fn: () => Dispatcher.dispatch('quizReports:generate', 'student_analysis'),
      of: () => fakeServer.requests.length,
      by: 0,
    }).then(
      () => {
        throw new Error('should not resolve!')
      },
      error => {
        expect(error.message).toContain('report is already generated')
      }
    )
  })
})
