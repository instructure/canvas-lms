/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {isEmpty} from 'es-toolkit/compat'
import ProgressStore from '../ProgressStore'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()
let progress_id
let progress

describe('ProgressStoreSpec', () => {
  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    progress_id = 2
    progress = {
      id: progress_id,
      context_id: 1,
      context_type: 'EpubExport',
      user_id: 1,
      tag: 'epub_export',
      completion: 0,
      workflow_state: 'queued',
    }
  })

  afterEach(() => {
    ProgressStore.clearState()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('get', async function () {
    server.use(
      http.get('/api/v1/progress/:id', ({params}) => {
        if (params.id === String(progress_id)) {
          return HttpResponse.json(progress)
        }
        return new HttpResponse(null, {status: 404})
      }),
    )

    // precondition
    expect(isEmpty(ProgressStore.getState())).toBeTruthy()

    // ProgressStore.get doesn't return a promise, so we need to wait for the state to update
    ProgressStore.get(progress_id)

    // Wait for the async request to complete
    await new Promise(resolve => setTimeout(resolve, 10))

    const state = ProgressStore.getState()
    expect(state[progress.id]).toEqual(progress)
  })
})
