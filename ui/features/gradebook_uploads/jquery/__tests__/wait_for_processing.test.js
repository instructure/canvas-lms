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

describe('waitForProcessing', () => {
  let progress
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
  })

  /**
   * This allows us to pass a function to mockImplementation for ajaxJSON
   * that will return pending workflow status until a desired number of
   * calls are made and finalState on the next call. After that it will
   * return the nextValue to allow the retrieval of the mock gradebook.
   */
  function delayedProcessingSimulator(maxCalls, finalState, nextValue = null) {
    let totalCalls = 0
    let completed = false
    return () => ({
      promise: () => {
        if (completed) {
          return Promise.resolve(nextValue)
        } else {
          totalCalls++
          if (totalCalls >= maxCalls) {
            completed = true
            return Promise.resolve(finalState)
          }
        }
        return Promise.resolve(progress.queued)
      },
    })
  }

  it('processes eventual successes', () => {
    const gradeBook = {id: 123}
    const mock_ajax = jest
      .spyOn($, 'ajaxJSON')
      .mockImplementation(delayedProcessingSimulator(2, progress.completed, gradeBook))

    return waitForProcessing(progress.queued, 0).then(gb => {
      expect(gb).toBe(gradeBook)
      expect(mock_ajax.mock.calls.length).toBe(3) // 2x progress, 1x gradebook
    })
  })

  it('handles eventual failures', () => {
    const mock_ajax = jest
      .spyOn($, 'ajaxJSON')
      .mockImplementation(delayedProcessingSimulator(2, progress.failed))

    return waitForProcessing(progress.queued, 0).catch(() => {
      expect(mock_ajax.mock.calls.length).toBe(2) // 2x progress, 0x gradebook
    })
  })

  it('handles unknown errors', () => {
    return waitForProcessing(progress.failed).catch(error => {
      expect(error.message).toBe(
        'An unknown error has occurred. Verify the CSV file or try again later.'
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
    jest.spyOn($, 'ajaxJSON').mockImplementation(() => {
      return {
        promise: () => null,
      }
    })
    return waitForProcessing(progress.completed).then(() => {
      // spinner is created
      expect(document.querySelector('#spinner .spinner')).not.toBe(null)

      // spinner is hidden
      expect(document.getElementById('spinner').style.display).toBe('none')
    })
  })
})
