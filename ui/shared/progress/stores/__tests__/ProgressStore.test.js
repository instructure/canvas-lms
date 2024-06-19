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

import {isEmpty} from 'lodash'
import ProgressStore from '../ProgressStore'
import sinon from 'sinon'

let progress_id
let progress
let server

describe('ProgressStoreSpec', () => {
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
    server = sinon.fakeServer.create()
  })

  afterEach(() => {
    ProgressStore.clearState()
    server.restore()
  })

  it('get', function () {
    server.respondWith('GET', `/api/v1/progress/${progress_id}`, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(progress),
    ])
    // precondition
    expect(isEmpty(ProgressStore.getState())).toBeTruthy()
    ProgressStore.get(progress_id)
    server.respond()
    const state = ProgressStore.getState()
    expect(state[progress.id]).toEqual(progress)
  })
})
