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
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import RequestDispatch, {
  DEFAULT_ACTIVE_REQUEST_LIMIT,
  MAX_ACTIVE_REQUEST_LIMIT,
  MIN_ACTIVE_REQUEST_LIMIT
} from '..'
import FakeServer from '../../__tests__/FakeServer'

describe('Shared > Network > RequestDispatch', () => {
  const URL = 'http://localhost/example'

  let dispatch
  let server

  beforeEach(() => {
    dispatch = new RequestDispatch({activeRequestLimit: 2})
  })

  describe('#options', () => {
    describe('.activeRequestLimit', () => {
      it('is set to the given value', () => {
        const {options} = new RequestDispatch({activeRequestLimit: 4})
        expect(options.activeRequestLimit).toBe(4)
      })

      it(`defaults to ${DEFAULT_ACTIVE_REQUEST_LIMIT}`, () => {
        const {options} = new RequestDispatch()
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })

      it(`clips values higher than ${MAX_ACTIVE_REQUEST_LIMIT}`, () => {
        const {options} = new RequestDispatch({activeRequestLimit: 101})
        expect(options.activeRequestLimit).toBe(MAX_ACTIVE_REQUEST_LIMIT)
      })

      it(`clips values lower than ${MIN_ACTIVE_REQUEST_LIMIT}`, () => {
        const {options} = new RequestDispatch({activeRequestLimit: 0})
        expect(options.activeRequestLimit).toBe(MIN_ACTIVE_REQUEST_LIMIT)
      })

      it('converts valid string numbers', () => {
        const {options} = new RequestDispatch({activeRequestLimit: '24'})
        expect(options.activeRequestLimit).toBe(24)
      })

      it('rejects invalid strings', () => {
        const {options} = new RequestDispatch({activeRequestLimit: 'invalid'})
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })

      it('rejects null', () => {
        const {options} = new RequestDispatch({activeRequestLimit: null})
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })

      it('rejects undefined', () => {
        const {options} = new RequestDispatch({activeRequestLimit: undefined})
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })
    })
  })

  describe('#getJSON()', () => {
    let exampleData

    function stageRequests(resourceCount) {
      for (let resourceIndex = 1; resourceIndex <= resourceCount; resourceIndex++) {
        exampleData[resourceIndex] = {resourceIndex}
        server.for(URL, {resourceIndex}).respond({status: 200, body: exampleData[resourceIndex]})
      }
    }

    function getJSON(resourceIndex) {
      return new Promise((resolve, reject) => {
        /* eslint-disable promise/catch-or-return */
        dispatch
          .getJSON(URL, {resourceIndex})
          .then(resolve)
          .fail(reject)
        /* eslint-enable promise/catch-or-return */
      })
    }

    beforeEach(() => {
      exampleData = {}
      server = new FakeServer()
      stageRequests(4)
    })

    afterEach(() => {
      server.teardown()
    })

    it('sends a request for the resource', async () => {
      await getJSON(1)
      expect(server.receivedRequests).toHaveLength(1)
    })

    it('resolves with the data from the request', async () => {
      const datum = await getJSON(1)
      expect(datum).toEqual(exampleData[1])
    })

    it('resolves when flooded with requests', async () => {
      const requests = [1, 2, 3, 4].map(getJSON)
      await Promise.all(requests)
      expect(server.receivedRequests).toHaveLength(4) // 4 resources
    })
  })

  describe('#getDepaginated()', () => {
    let exampleData

    function stageRequests(resourceCount, pagesPerResource) {
      for (let resourceIndex = 1; resourceIndex <= resourceCount; resourceIndex++) {
        exampleData[resourceIndex] = []
        for (let pageIndex = 1; pageIndex <= pagesPerResource; pageIndex++) {
          exampleData[resourceIndex].push({pageIndex, resourceIndex})
        }

        const pageResponses = exampleData[resourceIndex].map(body => ({status: 200, body}))
        server.for(URL, {resourceIndex}).respond(pageResponses)
      }
    }

    function getDepaginated(resourceIndex) {
      return new Promise((resolve, reject) => {
        /* eslint-disable promise/catch-or-return */
        dispatch
          .getDepaginated(URL, {resourceIndex})
          .then(resolve)
          .fail(reject)
        /* eslint-enable promise/catch-or-return */
      })
    }

    beforeEach(() => {
      exampleData = {}
      server = new FakeServer()
      stageRequests(4, 4)
    })

    afterEach(() => {
      server.teardown()
    })

    it('sends requests for each page of the resource', async () => {
      await getDepaginated(1)
      expect(server.receivedRequests).toHaveLength(4)
    })

    it('resolves with all data aggregated from each page', async () => {
      const data = await getDepaginated(1)
      expect(data).toEqual(exampleData[1])
    })

    it('resolves when flooded with requests', async () => {
      const requests = [1, 2, 3, 4].map(getDepaginated)
      await Promise.all(requests)
      expect(server.receivedRequests).toHaveLength(16) // 4 pages each across 4 resources
    })
  })
})
