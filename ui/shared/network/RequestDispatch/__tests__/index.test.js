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

import sinon from 'sinon'

import {NetworkFake, setPaginationLinkHeader} from '../../NetworkFake/index'
import RequestDispatch, {
  DEFAULT_ACTIVE_REQUEST_LIMIT,
  MAX_ACTIVE_REQUEST_LIMIT,
  MIN_ACTIVE_REQUEST_LIMIT,
} from '../index'

describe('Shared > Network > RequestDispatch', () => {
  const URL = 'http://localhost/example'

  let dispatch
  let network

  beforeEach(() => {
    dispatch = new RequestDispatch({activeRequestLimit: 2})
  })

  function rangeOfLength(length) {
    return Array.from({length}).map((_, index) => index)
  }

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
    function getJSON(params) {
      return dispatch.getJSON(URL, params)
    }

    beforeEach(() => {
      network = new NetworkFake()
    })

    afterEach(() => {
      network.restore()
    })

    it('sends a request for the resource', async () => {
      getJSON()
      await network.allRequestsReady()
      expect(network.getRequests()).toHaveLength(1)
    })

    it('uses the given url for the request', async () => {
      getJSON()
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.path).toEqual(URL)
    })

    it('includes the given params in the request', async () => {
      getJSON({example: true})
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.params).toEqual({example: 'true'})
    })

    it('resolves with the data from the request', async () => {
      const result = getJSON()
      await network.allRequestsReady()
      const [{response}] = network.getRequests()
      response.setJson({example: true})
      response.send()
      expect(await result).toEqual({example: true})
    })

    it('resolves when flooded with requests', async () => {
      const clock = sinon.useFakeTimers()
      const requests = rangeOfLength(4).map(() => getJSON())
      for await (const [index] of requests.entries()) {
        // Get the next request
        const request = network.getRequests()[index]
        // Wait for that request to be registered
        await request.isReady()
        // Respond
        request.response.setJson({requestIndex: index})
        request.response.send()
        clock.tick(1)
      }
      expect(await Promise.all(requests)).toHaveLength(4)
      clock.restore()
    })
  })

  describe('#getDepaginated()', () => {
    function getDepaginated(...args) {
      return dispatch.getDepaginated(URL, ...args)
    }

    beforeEach(() => {
      network = new NetworkFake()
    })

    afterEach(() => {
      network.restore()
    })

    it('sends a request for the resource', async () => {
      getDepaginated()
      await network.allRequestsReady()
      expect(network.getRequests()).toHaveLength(1)
    })

    it('uses the given url for the request', async () => {
      getDepaginated()
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.path).toEqual(URL)
    })

    it('includes the given params in the request', async () => {
      getDepaginated({example: true})
      await network.allRequestsReady()
      const [request] = network.getRequests()
      expect(request.params).toEqual({example: 'true'})
    })

    describe('when the first page responds', () => {
      async function resolveFirstPage() {
        await network.allRequestsReady()
        const [{response}] = network.getRequests()
        setPaginationLinkHeader(response, {last: 3})
        response.setJson([{example: true}])
        response.send()
        await network.allRequestsReady()
      }

      it('calls the page callback when provided', async () => {
        const pageCallback = sinon.spy()
        getDepaginated(null, pageCallback)
        await resolveFirstPage()
        expect(pageCallback.callCount).toEqual(1)
      })

      it('calls the page callback with the data from the first request', async () => {
        const pageCallback = sinon.spy()
        getDepaginated(null, pageCallback)
        await resolveFirstPage()
        const [data] = pageCallback.lastCall.args
        expect(data).toEqual([{example: true}])
      })

      it('sends a request for each additional page', async () => {
        getDepaginated()
        await resolveFirstPage()
        expect(network.getRequests()).toHaveLength(3)
      })

      it('uses the same path for each additional request', async () => {
        getDepaginated()
        await resolveFirstPage()
        const paths = network.getRequests().map(request => request.path)
        expect(paths).toEqual([URL, URL, URL])
      })

      it('uses the same parameters for each additional request', async () => {
        getDepaginated()
        await resolveFirstPage()
        const [{params}] = network.getRequests()
        const pagesParams = network.getRequests().map(request => {
          const {page, ...pageParams} = request.params
          return pageParams
        })
        expect(pagesParams).toEqual([params, params, params])
      })

      it('calls the "pages enqueued" callback when provided', async () => {
        const pagesEnqueued = sinon.spy()
        getDepaginated(null, null, pagesEnqueued)
        await resolveFirstPage()
        expect(pagesEnqueued.callCount).toEqual(1)
      })
    })

    describe('when each page responds', () => {
      async function resolvePages() {
        const clock = sinon.useFakeTimers()
        await network.allRequestsReady()

        const [request1] = network.getRequests()
        setPaginationLinkHeader(request1.response, {last: 3})
        request1.response.setJson([{dataForPage: 1}])
        request1.response.send()
        clock.tick(1)

        await network.allRequestsReady()
        const [, request2, request3] = network.getRequests()

        setPaginationLinkHeader(request2.response, {last: 3})
        request2.response.setJson([{dataForPage: 2}])
        request2.response.send()
        clock.tick(1)

        setPaginationLinkHeader(request3.response, {last: 3})
        request3.response.setJson([{dataForPage: 3}])
        request3.response.send()
        clock.tick(1)
        clock.restore()
      }

      it('calls the page callback for each page', async () => {
        const pageCallback = sinon.spy()
        getDepaginated(null, pageCallback)
        await resolvePages()
        expect(pageCallback.callCount).toEqual(3)
      })

      it('calls the page callback with the data from each request', async () => {
        const pageCallback = sinon.spy()
        getDepaginated(null, pageCallback)
        await resolvePages()
        const data = pageCallback.getCalls().map(call => call.args[0])
        expect(data).toEqual([[{dataForPage: 1}], [{dataForPage: 2}], [{dataForPage: 3}]])
      })
    })

    describe('when all pages have responded', () => {
      it('resolves with all data aggregated from each page', async () => {
        const result = getDepaginated()
        await network.allRequestsReady()

        const [request1] = network.getRequests()
        setPaginationLinkHeader(request1.response, {last: 3})
        request1.response.setJson([{dataForPage: 1}])
        request1.response.send()

        await network.allRequestsReady()
        const [, request2, request3] = network.getRequests()

        setPaginationLinkHeader(request2.response, {last: 3})
        request2.response.setJson([{dataForPage: 2}])
        request2.response.send()

        setPaginationLinkHeader(request3.response, {last: 3})
        request3.response.setJson([{dataForPage: 3}])
        request3.response.send()

        expect(await result).toEqual([{dataForPage: 1}, {dataForPage: 2}, {dataForPage: 3}])
      })
    })

    it('resolves when flooded with requests', async () => {
      const clock = sinon.useFakeTimers()
      const depaginatedRequestCount = 4
      const pagesPerResource = 3
      const totalRequestCount = depaginatedRequestCount * pagesPerResource

      const requests = rangeOfLength(depaginatedRequestCount).map(() => getDepaginated())
      await network.allRequestsReady()

      for await (const index of rangeOfLength(totalRequestCount)) {
        // Get the next request
        const request = network.getRequests()[index]
        // Wait for that request to be registered
        await request.isReady()
        // Respond
        setPaginationLinkHeader(request.response, {last: pagesPerResource})
        request.response.setJson([{requestIndex: index}])
        request.response.send()
        clock.tick(1)
      }

      expect(await Promise.all(requests)).toHaveLength(depaginatedRequestCount)
      clock.restore()
    })

    describe('when only one page of data is available', () => {
      async function resolveFirstPage() {
        await network.allRequestsReady()
        const [{response}] = network.getRequests()
        setPaginationLinkHeader(response, {last: 1})
        response.setJson([{example: true}])
        response.send()
        await network.allRequestsReady()
      }

      it('does not send additional requests', async () => {
        const result = getDepaginated()
        await resolveFirstPage()
        await result
        expect(network.getRequests()).toHaveLength(1)
      })

      it('calls the "pages enqueued" callback when provided', async () => {
        const pagesEnqueued = sinon.spy()
        getDepaginated(null, null, pagesEnqueued)
        await resolveFirstPage()
        expect(pagesEnqueued.callCount).toEqual(1)
      })

      it('resolves with the data from the first page', async () => {
        const result = getDepaginated()
        await resolveFirstPage()
        expect(await result).toEqual([{example: true}])
      })
    })

    describe('when the params include a key like "page"', () => {
      it('is not confused by the parameter with a similar name', async () => {
        /*
         * A previous implementation of link header parsing did not match the
         * 'page' parameter using word boundaries. So a parameter of 'per_page'
         * would be used instead if it preceded the requested page index,
         * leading to either an incomplete set of data or more likely a large
         * number of wasteful requests for pages without data.
         */
        getDepaginated({per_page: 50})
        await network.allRequestsReady()
        const [{response}] = network.getRequests()
        setPaginationLinkHeader(response, {last: 3})
        response.setJson([{example: true}])
        response.send()
        await network.allRequestsReady()
        expect(network.getRequests()).toHaveLength(3)
      })
    })

    describe('if the first page response lacks a pagination header', () => {
      async function resolveFirstPage() {
        await network.allRequestsReady()
        const [{response}] = network.getRequests()
        response.setJson([{example: true}])
        response.send()
        await network.allRequestsReady()
      }

      it('does not send additional requests', async () => {
        const result = getDepaginated()
        await resolveFirstPage()
        await result
        expect(network.getRequests()).toHaveLength(1)
      })

      it('calls the "pages enqueued" callback when provided', async () => {
        const pagesEnqueued = sinon.spy()
        getDepaginated(null, null, pagesEnqueued)
        await resolveFirstPage()
        expect(pagesEnqueued.callCount).toEqual(1)
      })

      it('resolves with the data from the first page', async () => {
        const result = getDepaginated()
        await resolveFirstPage()
        expect(await result).toEqual([{example: true}])
      })
    })

    describe('if the pagination header does not include the last page', () => {
      async function resolveFirstPage() {
        await network.allRequestsReady()
        const [{response}] = network.getRequests()
        setPaginationLinkHeader(response, {next: 2})
        response.setJson([{example: true}])
        response.send()
        await network.allRequestsReady()
      }

      it('does not send additional requests', async () => {
        const result = getDepaginated()
        await resolveFirstPage()
        await result
        expect(network.getRequests()).toHaveLength(1)
      })

      it('calls the "pages enqueued" callback when provided', async () => {
        const pagesEnqueued = sinon.spy()
        getDepaginated(null, null, pagesEnqueued)
        await resolveFirstPage()
        expect(pagesEnqueued.callCount).toEqual(1)
      })

      it('resolves with the data from the first page', async () => {
        const result = getDepaginated()
        await resolveFirstPage()
        expect(await result).toEqual([{example: true}])
      })
    })

    describe('if the last page pagination header link is not a number', () => {
      async function resolveFirstPage() {
        await network.allRequestsReady()
        const [{response}] = network.getRequests()
        setPaginationLinkHeader(response, {last: 'invalid'})
        response.setJson([{example: true}])
        response.send()
        await network.allRequestsReady()
      }

      it('does not send additional requests', async () => {
        const result = getDepaginated()
        await resolveFirstPage()
        await result
        expect(network.getRequests()).toHaveLength(1)
      })

      it('calls the "pages enqueued" callback when provided', async () => {
        const pagesEnqueued = sinon.spy()
        getDepaginated(null, null, pagesEnqueued)
        await resolveFirstPage()
        expect(pagesEnqueued.callCount).toEqual(1)
      })

      it('resolves with the data from the first page', async () => {
        const result = getDepaginated()
        await resolveFirstPage()
        expect(await result).toEqual([{example: true}])
      })
    })
  })
})
