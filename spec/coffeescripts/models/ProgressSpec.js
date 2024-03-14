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

import Progress from '@canvas/progress/backbone/models/Progress'

let server = null
let clock = null
let model = null

QUnit.module('progressable', {
  setup() {
    server = sinon.fakeServer.create()
    clock = sinon.useFakeTimers()
    model = new Progress()
    // sinon won't send different data to the same url, so we change it
    model.url = () => `/steve/${new Date().getTime()}`
  },
  teardown() {
    server.restore()
    clock.restore()
  },
})
const respond = data =>
  server.respond('GET', model.url(), [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(data),
  ])

test('polls the progress api until the job is finished', () => {
  const spy = sinon.spy()
  model.on('complete', spy)
  model.poll()
  respond({workflow_state: 'queued'})
  clock.tick(1000)
  equal(model.get('workflow_state'), 'queued')
  respond({workflow_state: 'running'})
  clock.tick(1000)
  equal(model.get('workflow_state'), 'running')
  respond({workflow_state: 'completed'})
  clock.tick(1000)
  equal(model.get('workflow_state'), 'completed')
  ok(spy.calledOnce)
})
