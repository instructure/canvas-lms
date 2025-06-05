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

// Helper to clean up any iframes created during tests
const cleanupIframes = () => {
  const iframes = document.querySelectorAll('iframe')
  iframes.forEach(iframe => iframe.parentNode?.removeChild(iframe))
}

const server = setupServer()

beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))
afterEach(async () => {
  server.resetHandlers()
  cleanupIframes()
  // __reset__() will clear all callbacks
  subject.__reset__()
  // Restore any mocked functions
  if (document.createElement.mockRestore) {
    document.createElement.mockRestore()
  }
  // Give a moment for any pending async operations to settle
  await sleep(10)
})
afterAll(() => server.close())

beforeEach(() => {
  config.ajax = $.ajax
  config.quizReportsUrl = 'http://localhost/reports'
  cleanupIframes()
  // Ensure we start with a clean state
  subject.__reset__()
})

describe('.populate', function () {
  it('does not auto-download reports when autoDownload is false', async () => {
    // Make sure we start with a clean state
    subject.__reset__()
    cleanupIframes()

    // Spy on document.createElement to detect iframe creation
    const originalCreateElement = document.createElement.bind(document)
    let iframeCreated = false
    document.createElement = jest.fn(tagName => {
      if (tagName.toLowerCase() === 'iframe') {
        iframeCreated = true
      }
      return originalCreateElement(tagName)
    })

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
    expect(iframeCreated).toBe(false)

    // Restore the original function
    document.createElement = originalCreateElement
  })
})
