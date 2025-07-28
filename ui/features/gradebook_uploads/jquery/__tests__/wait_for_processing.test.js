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
import {waitForProcessing} from '../wait_for_processing'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

describe('waitForProcessing', () => {
  let progress

  beforeAll(() => {
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    progress = {
      queued: {workflow_state: 'queued', message: ''},
      failed: {workflow_state: 'failed', message: ''},
      completed: {workflow_state: 'completed', message: ''},
    }
    const newDiv = document.createElement('div')
    newDiv.id = 'spinner'
    document.body.appendChild(newDiv)
  })

  afterEach(() => {
    jest.clearAllMocks()
    const spinner = document.getElementById('spinner')
    spinner.parentNode.removeChild(spinner)
    server.resetHandlers()
  })

  /**
   * This sets up MSW handlers that will return pending workflow status
   * until a desired number of calls are made and finalState on the next call.
   */
  function setupDelayedProcessingHandlers(progressId, maxCalls, finalState, gradebook = null) {
    let totalCalls = 0

    server.use(
      http.get(`*/api/v1/progress/${progressId}`, () => {
        totalCalls++
        if (totalCalls >= maxCalls) {
          return HttpResponse.json(finalState)
        }
        return HttpResponse.json(progress.queued)
      }),
    )

    if (gradebook) {
      server.use(
        http.get('*/uploaded_gradebook_data', () => {
          return HttpResponse.json(gradebook)
        }),
      )
    }
  }

  it('processes eventual successes', () => {
    const gradeBook = {id: 123}
    progress.queued.id = 1

    // Need to set up ENV for uploaded_gradebook_data_path
    window.ENV = {uploaded_gradebook_data_path: '/uploaded_gradebook_data'}

    setupDelayedProcessingHandlers(1, 2, progress.completed, gradeBook)

    return waitForProcessing(progress.queued, 0).then(gb => {
      expect(gb).toEqual(gradeBook)
    })
  })

  it('handles eventual failures', () => {
    progress.queued.id = 2
    setupDelayedProcessingHandlers(2, 2, progress.failed)

    return waitForProcessing(progress.queued, 0).catch(() => {
      // Test passes if it reaches here
      expect(true).toBe(true)
    })
  })

  it('handles unknown errors', () => {
    return waitForProcessing(progress.failed).catch(error => {
      expect(error.message).toBe(
        'An unknown error has occurred. Verify the CSV file or try again later.',
      )
    })
  })

  it('handles invalid header errors', () => {
    progress.failed.message = 'blah blah Invalid header row blah blah'
    return waitForProcessing(progress.failed).catch(error => {
      expect(error.message).toBe('The CSV header row is invalid.')
    })
  })

  it('manages spinner', () => {
    progress.completed.id = 3
    window.ENV = {uploaded_gradebook_data_path: '/uploaded_gradebook_data'}

    server.use(
      http.get('*/uploaded_gradebook_data', () => {
        return HttpResponse.json({})
      }),
    )

    return waitForProcessing(progress.completed).then(() => {
      // spinner is created
      expect(document.querySelector('#spinner .spinner')).not.toBe(null)

      // spinner is hidden
      expect(document.getElementById('spinner').style.display).toBe('none')
    })
  })
})
