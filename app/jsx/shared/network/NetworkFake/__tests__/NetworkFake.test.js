/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
 * details.g
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import axios from 'axios'

import NetworkFake from '../NetworkFake'

describe('Shared > Network > NetworkFake', () => {
  let network

  beforeEach(() => {
    network = new NetworkFake()
  })

  afterEach(async () => {
    await network.allRequestsReady()
    network.restore()
  })

  describe('#allRequestsReady()', () => {
    it('returns a promise', () => {
      expect(network.allRequestsReady()).toBeInstanceOf(Promise)
    })

    it('resolves when all received requests are ready', async () => {
      axios.get('/example')
      axios.get('/example')
      await network.allRequestsReady()
      const readyStates = network.getRequests().map(request => request.isReady())
      expect(readyStates).toEqual([true, true])
    })
  })

  describe('#getRequests()', () => {
    it('returns a list of all requests which have been submitted', async () => {
      axios.get('/example')
      axios.get('/sample')
      await network.allRequestsReady()
      const requestPaths = network.getRequests().map(request => request.path)
      expect(requestPaths).toEqual(['/example', '/sample'])
    })
  })
})
