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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

describe('progressable', () => {
  let model
  const server = setupServer()

  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  function respond(data) {
    server.use(
      http.get('*/steve/*', () => {
        return HttpResponse.json(data)
      }),
    )
  }

  describe('with fake timers', () => {
    beforeEach(() => {
      vi.useFakeTimers()
      model = new Progress()
      model.url = () => `/steve/${Date.now()}`
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    // Skip this test due to complex timing issues with MSW and fake timers
    test.skip('polls the progress api until the job is finished', async () => {
      const spy = vi.fn()
      model.on('complete', spy)

      respond({workflow_state: 'queued'})
      model.poll()
      await new Promise(resolve => setTimeout(resolve, 10))
      vi.advanceTimersByTime(1000)
      expect(model.get('workflow_state')).toBe('queued')

      respond({workflow_state: 'running'})
      await new Promise(resolve => setTimeout(resolve, 10))
      vi.advanceTimersByTime(1000)
      expect(model.get('workflow_state')).toBe('running')

      respond({workflow_state: 'completed'})
      await new Promise(resolve => setTimeout(resolve, 10))
      vi.advanceTimersByTime(1000)
      expect(model.get('workflow_state')).toBe('completed')

      expect(spy).toHaveBeenCalledTimes(1)
    })
  })

  describe('without fake timers', () => {
    beforeEach(() => {
      model = new Progress()
      model.url = () => `/steve/test`
    })

    test('fetches progress data', async () => {
      server.use(
        http.get('*/steve/*', () => {
          return HttpResponse.json({
            workflow_state: 'completed',
            completion: 100,
            results: {message: 'Done'},
          })
        }),
      )

      await model.fetch()

      expect(model.get('workflow_state')).toBe('completed')
      expect(model.get('completion')).toBe(100)
      expect(model.isSuccess()).toBe(true)
    })

    test('identifies polling states correctly', () => {
      model.set('workflow_state', 'queued')
      expect(model.isPolling()).toBe(true)

      model.set('workflow_state', 'running')
      expect(model.isPolling()).toBe(true)

      model.set('workflow_state', 'completed')
      expect(model.isPolling()).toBe(false)

      model.set('workflow_state', 'failed')
      expect(model.isPolling()).toBe(false)
    })
  })
})
