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

import progressable from '../progressable'
import {Model} from '@canvas/backbone'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toBe(y)

const progressUrl = '/progress'
let quizModel = null

class QuizCSV extends Model {}
QuizCSV.mixin(progressable)

const server = setupServer(
  http.get(progressUrl, () => {
    return HttpResponse.json({workflow_state: 'completed'})
  }),
  http.get('/quiz_csv', () => {
    return HttpResponse.json({csv: 'one,two,three'})
  }),
)

// Helper to wait for the progressResolved event
function waitForProgressResolved(model) {
  return new Promise(resolve => {
    model.on('progressResolved', resolve)
  })
}

describe('progressable', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    quizModel = new QuizCSV()
    quizModel.url = '/quiz_csv'
    // Set polling timeout to 0 for faster tests
    quizModel.progressModel.set('timeout', 0)
  })

  test('set progress_url', async () => {
    const spy = vi.fn()
    quizModel.progressModel.on('complete', spy)
    quizModel.on('progressResolved', spy)

    const progressPromise = waitForProgressResolved(quizModel)
    quizModel.set({progress_url: progressUrl})

    await progressPromise

    ok(spy.mock.calls.length === 2, 'complete and progressResolved handlers called')
    equal(quizModel.progressModel.get('workflow_state'), 'completed')
    equal(quizModel.get('csv'), 'one,two,three')
  })

  test('set progress.url', async () => {
    const spy = vi.fn()
    quizModel.progressModel.on('complete', spy)
    quizModel.on('progressResolved', spy)

    const progressPromise = waitForProgressResolved(quizModel)
    quizModel.progressModel.set({url: progressUrl, workflow_state: 'queued'})

    await progressPromise

    ok(spy.mock.calls.length === 2, 'complete and progressResolved handlers called')
    equal(quizModel.progressModel.get('workflow_state'), 'completed')
    equal(quizModel.get('csv'), 'one,two,three')
  })
})
