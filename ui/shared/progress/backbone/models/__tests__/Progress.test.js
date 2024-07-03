/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Progress from '../Progress'

describe('progressable', () => {
  let server
  let model

  beforeEach(() => {
    jest.useFakeTimers()
    server = require('sinon').fakeServer.create() // You might need to adjust how you import or require sinon
    model = new Progress()
    model.url = () => `/steve/${Date.now()}`
  })

  afterEach(() => {
    server.restore()
    jest.useRealTimers()
  })

  function respond(data) {
    server.respondWith('GET', model.url(), [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(data),
    ])
    server.respond() // Ensure that sinon's fake server responds immediately
  }

  test('polls the progress api until the job is finished', () => {
    const spy = jest.fn()
    model.on('complete', spy)
    model.poll()

    respond({workflow_state: 'queued'})
    jest.advanceTimersByTime(1000)
    expect(model.get('workflow_state')).toBe('queued')

    respond({workflow_state: 'running'})
    jest.advanceTimersByTime(1000)
    expect(model.get('workflow_state')).toBe('running')

    respond({workflow_state: 'completed'})
    jest.advanceTimersByTime(1000)
    expect(model.get('workflow_state')).toBe('completed')

    expect(spy).toHaveBeenCalledTimes(1)
  })
})
