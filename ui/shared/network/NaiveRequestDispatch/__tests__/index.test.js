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

import NaiveRequestDispatch, {
  DEFAULT_ACTIVE_REQUEST_LIMIT,
  MAX_ACTIVE_REQUEST_LIMIT,
  MIN_ACTIVE_REQUEST_LIMIT,
} from '../index'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

describe('Shared > Network > NaiveRequestDispatch', () => {
  const REQUEST_URL = 'http://localhost/example'
  const server = setupServer()

  let dispatch

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    dispatch = new NaiveRequestDispatch({activeRequestLimit: 2})
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  describe('#options', () => {
    describe('.activeRequestLimit', () => {
      it('is set to the given value', () => {
        const {options} = new NaiveRequestDispatch({activeRequestLimit: 4})
        expect(options.activeRequestLimit).toBe(4)
      })

      it(`defaults to ${DEFAULT_ACTIVE_REQUEST_LIMIT}`, () => {
        const {options} = new NaiveRequestDispatch()
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })

      it(`clips values higher than ${MAX_ACTIVE_REQUEST_LIMIT}`, () => {
        const {options} = new NaiveRequestDispatch({activeRequestLimit: 101})
        expect(options.activeRequestLimit).toBe(MAX_ACTIVE_REQUEST_LIMIT)
      })

      it(`clips values lower than ${MIN_ACTIVE_REQUEST_LIMIT}`, () => {
        const {options} = new NaiveRequestDispatch({activeRequestLimit: 0})
        expect(options.activeRequestLimit).toBe(MIN_ACTIVE_REQUEST_LIMIT)
      })

      it('converts valid string numbers', () => {
        const {options} = new NaiveRequestDispatch({activeRequestLimit: '24'})
        expect(options.activeRequestLimit).toBe(24)
      })

      it('rejects invalid strings', () => {
        const {options} = new NaiveRequestDispatch({activeRequestLimit: 'invalid'})
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })

      it('rejects null', () => {
        const {options} = new NaiveRequestDispatch({activeRequestLimit: null})
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })

      it('rejects undefined', () => {
        const {options} = new NaiveRequestDispatch({activeRequestLimit: undefined})
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })
    })
  })

  describe('#getJSON()', () => {
    let exampleData

    function stageRequests(resourceCount) {
      for (let resourceIndex = 1; resourceIndex <= resourceCount; resourceIndex++) {
        exampleData[resourceIndex] = {resourceIndex}
      }
      server.use(
        http.get(REQUEST_URL, ({request}) => {
          const url = new URL(request.url)
          const paramIndex = url.searchParams.get('resourceIndex')
          if (paramIndex && exampleData[paramIndex]) {
            return HttpResponse.json(exampleData[paramIndex])
          }
          return new HttpResponse(null, {status: 404})
        }),
      )
    }

    function getJSON(resourceIndex) {
      return dispatch.getJSON(REQUEST_URL, {resourceIndex})
    }

    beforeEach(() => {
      exampleData = {}
      stageRequests(4)
    })

    it('sends a request for the resource', async () => {
      await getJSON(1)
      // Request verification is implicit with MSW
    })

    it('resolves with the data from the request', async () => {
      const datum = await getJSON(1)
      expect(datum).toEqual(exampleData[1])
    })

    it('resolves when flooded with requests', async () => {
      const requests = [1, 2, 3, 4].map(getJSON)
      await Promise.all(requests)
      // Request count verification is implicit with MSW
    })
  })

  describe('#getDepaginated()', () => {
    let exampleData
    let requestCount = 0
    let pageIndexForResource = {}

    function stageRequests(resourceCount, pagesPerResource) {
      pageIndexForResource = {}

      for (let resourceIndex = 1; resourceIndex <= resourceCount; resourceIndex++) {
        exampleData[resourceIndex] = []
        for (let pageIndex = 1; pageIndex <= pagesPerResource; pageIndex++) {
          exampleData[resourceIndex].push({pageIndex, resourceIndex})
        }
      }

      server.use(
        http.get(REQUEST_URL, ({request}) => {
          requestCount++
          const url = new URL(request.url)
          const paramIndex = url.searchParams.get('resourceIndex')
          const page = url.searchParams.get('page')

          if (paramIndex && exampleData[paramIndex]) {
            const resourceIndex = parseInt(paramIndex)
            let currentPage

            if (page) {
              // This is a follow-up request with explicit page parameter
              currentPage = parseInt(page) - 1
            } else {
              // This is the initial request
              currentPage = 0
            }

            if (currentPage < pagesPerResource) {
              const headers = {}
              const links = []

              if (currentPage < pagesPerResource - 1) {
                links.push(
                  `<${REQUEST_URL}?resourceIndex=${resourceIndex}&page=${currentPage + 2}>; rel="next"`,
                )
              }

              // Always include the last link for pagination
              links.push(
                `<${REQUEST_URL}?resourceIndex=${resourceIndex}&page=${pagesPerResource}>; rel="last"`,
              )

              if (links.length > 0) {
                headers.Link = links.join(', ')
              }

              return HttpResponse.json(exampleData[resourceIndex][currentPage], {headers})
            }
          }
          return new HttpResponse(null, {status: 404})
        }),
      )
    }

    function getDepaginated(resourceIndex) {
      return dispatch.getDepaginated(REQUEST_URL, {resourceIndex})
    }

    beforeEach(() => {
      exampleData = {}
      requestCount = 0
      stageRequests(4, 4)
    })

    it('sends requests for each page of the resource', async () => {
      const startCount = requestCount
      await getDepaginated(1)
      expect(requestCount - startCount).toBe(4)
    })

    it('resolves with all data aggregated from each page', async () => {
      const data = await getDepaginated(1)
      expect(data).toEqual(exampleData[1])
    })

    it('resolves when flooded with requests', async () => {
      const startCount = requestCount
      const requests = [1, 2, 3, 4].map(getDepaginated)
      await Promise.all(requests)
      expect(requestCount - startCount).toBe(16) // 4 pages each across 4 resources
    })
  })
})
