// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import PerformanceControls from '../../PerformanceControls'
import {NetworkFake, setPaginationLinkHeader} from '@canvas/network/NetworkFake/index'
import store from '../index'
import type {CustomColumn} from '../../gradebook.d'
import sinon from 'sinon'

const exampleCustomColumns: CustomColumn[] = [
  {
    hidden: false,
    id: '2401',
    position: 0,
    read_only: false,
    teacher_notes: false,
    title: 'Custom Column 1',
  },
  {
    hidden: false,
    id: '2402',
    position: 1,
    read_only: false,
    teacher_notes: false,
    title: 'Custom Column 2',
  },
]

describe('customColumnsState', () => {
  const url = '/api/v1/courses/1/custom_gradebook_columns'
  let network
  let clock

  function getRequests() {
    return network.getRequests(request => request.path === url)
  }

  beforeEach(() => {
    network = new NetworkFake()
    clock = sinon.useFakeTimers()
  })

  afterEach(() => {
    clock.restore()
  })

  it('sends a request to the custom columns url', async () => {
    store.getState().fetchCustomColumns()
    await network.allRequestsReady()
    const requests = getRequests()
    expect(requests.length).toStrictEqual(1)
  })

  describe('when sending the initial request', () => {
    it('sets the `per_page` parameter to the configured per page maximum', async () => {
      store.setState({
        performanceControls: new PerformanceControls({customColumnsPerPage: 45}),
      })
      store.getState().fetchCustomColumns()
      await network.allRequestsReady()
      const [{params}] = getRequests()
      expect(params.per_page).toStrictEqual('45')
    })
  })

  describe('when the first page resolves', () => {
    beforeEach(async () => {
      store.getState().fetchCustomColumns()
      await network.allRequestsReady()
      const [{response}] = getRequests()
      setPaginationLinkHeader(response, {first: 1, current: 1, next: 2, last: 3})
      response.setJson(exampleCustomColumns.slice(0, 1))
      response.send()
      await network.allRequestsReady()
    })

    it('sends a request for each additional page', () => {
      const pages = getRequests()
        .slice(1)
        .map(request => request.params.page)
      expect(pages).toStrictEqual(['2', '3'])
    })

    it('uses the same path for each page', () => {
      const [{path}] = getRequests()
      getRequests()
        .slice(1)
        .forEach(request => {
          expect(request.path).toStrictEqual(path)
        })
    })

    it('uses the same parameters for each page', () => {
      const [{params}] = getRequests()
      getRequests()
        .slice(1)
        .forEach(request => {
          const {page, ...pageParams} = request.params
          expect(pageParams).toStrictEqual(params)
        })
    })
  })

  describe('when all pages have resolved', () => {
    beforeEach(async () => {
      clock = sinon.useFakeTimers()
      store.getState().fetchCustomColumns()
      await network.allRequestsReady()

      // Resolve the first page
      const [{response}] = getRequests()
      setPaginationLinkHeader(response, {first: 1, current: 1, next: 2, last: 3})
      response.setJson(exampleCustomColumns.slice(0, 1))
      response.send()
      clock.tick(1)
      await network.allRequestsReady()

      // Resolve the remaining pages
      const [request2, request3] = getRequests().slice(1)
      setPaginationLinkHeader(response, {first: 1, current: 1, next: 2, last: 3})
      request2.response.setJson(exampleCustomColumns.slice(1, 2))
      request2.response.send()
      clock.tick(1)

      setPaginationLinkHeader(response, {first: 1, current: 1, next: 2, last: 3})
      request3.response.setJson(exampleCustomColumns.slice(2, 3))
      request3.response.send()
      clock.tick(1)
    })

    it('includes the loaded custom columns when updating the gradebook', () => {
      expect(store.getState().customColumns).toStrictEqual(exampleCustomColumns)
    })
  })

  describe('if the first response does not link to the last page', () => {
    beforeEach(async () => {
      store.getState().fetchCustomColumns()
      await network.allRequestsReady()
      const [{response}] = getRequests()
      response.setJson(exampleCustomColumns.slice(0, 1))
      response.send()
      clock.tick(1)
      await network.allRequestsReady()
    })

    it('does not send additional requests', () => {
      expect(getRequests().length).toStrictEqual(2)
    })
  })
})
