/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

import NaiveFetchDispatch from '../NaiveFetchDispatch'

const server = setupServer()

describe('Outcomes > IndividualStudentMastery > NaiveFetchDispatch', () => {
  const URL = 'http://localhost/example'

  let dispatch
  let callCount

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    dispatch = new NaiveFetchDispatch({activeRequestLimit: 2})
    callCount = 0
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('#fetch()', () => {
    let exampleData

    function resourceUrl(resourceIndex) {
      return `${URL}/?index=${resourceIndex}`
    }

    function stageRequests(resourceCount) {
      for (let resourceIndex = 1; resourceIndex <= resourceCount; resourceIndex++) {
        exampleData[resourceIndex] = {resourceIndex}
      }
      // Set up MSW handler with wildcard to match query params
      server.use(
        http.get('http://localhost/example/', ({request}) => {
          callCount++
          // Extract index from URL string
          const urlStr = request.url
          const match = urlStr.match(/index=(\d+)/)
          const index = match ? parseInt(match[1], 10) : null
          return HttpResponse.json(exampleData[index])
        }),
      )
    }

    function fetch(resourceIndex) {
      return new Promise((resolve, reject) => {
        dispatch.fetch(resourceUrl(resourceIndex)).then(resolve).catch(reject)
      })
    }

    beforeEach(() => {
      exampleData = {}
      callCount = 0
      stageRequests(4)
    })

    it('sends a request for the resource', async () => {
      await fetch(1)
      expect(callCount).toBe(1)
    })

    it('resolves with the data from the request', async () => {
      const response = await fetch(1)
      expect(await response.json()).toMatchObject(exampleData[1])
    })

    it('resolves when flooded with requests', async () => {
      const requests = [1, 2, 3, 4].map(fetch)
      await Promise.all(requests)
      expect(callCount).toBe(4)
    })
  })
})
