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

import {renderHook} from '@testing-library/react-hooks/dom'
import PerformanceControls from '../../PerformanceControls'
import {RequestDispatch} from '@canvas/network'
import {NetworkFake, setPaginationLinkHeader} from '@canvas/network/NetworkFake/index'
import useModules from '../useModules'

const defaultProps = {
  gradebookEnv: {context_id: '1'},
  performance_controls: {
    students_chunk_size: 2 // students per page
  }
}

const courseId = '1'

const exampleData = {
  contextModules: [{id: '2601'}, {id: '2602 '}, {id: '2603'}]
}

describe('useModules', () => {
  const url = '/api/v1/courses/1/modules'
  let performanceControls
  let dispatch
  let network

  function getRequests() {
    return network.getRequests(request => request.path === url)
  }

  beforeEach(() => {
    performanceControls = new PerformanceControls(defaultProps.gradebookEnv.performance_controls)
    dispatch = new RequestDispatch({
      activeRequestLimit: performanceControls.activeRequestLimit
    })
    network = new NetworkFake()
  })

  it('starts loading if has_modules = true', () => {
    const {result} = renderHook(() =>
      useModules(dispatch, courseId, performanceControls.contextModulesPerPage, true)
    )
    expect(result.current.loading).toStrictEqual(true)
    expect(result.current.data).toStrictEqual([])
  })

  it('does not start loading if has_modules = false', () => {
    const {result} = renderHook(() =>
      useModules(dispatch, courseId, performanceControls.contextModulesPerPage, false)
    )
    expect(result.current.loading).toStrictEqual(false)
    expect(result.current.data).toStrictEqual([])
  })

  it('sends a request to the context modules url', async () => {
    renderHook(() =>
      useModules(dispatch, courseId, performanceControls.contextModulesPerPage, true)
    )
    await network.allRequestsReady()
    const requests = getRequests()
    expect(requests.length).toStrictEqual(1)
  })

  describe('when sending the initial request', () => {
    it('sets the `per_page` parameter to the configured per page maximum', async () => {
      performanceControls = new PerformanceControls({contextModulesPerPage: 45})
      renderHook(() =>
        useModules(dispatch, courseId, performanceControls.contextModulesPerPage, true)
      )
      await network.allRequestsReady()
      const [{params}] = getRequests()
      expect(params.per_page).toStrictEqual('45')
    })
  })

  describe('when the first page resolves', () => {
    beforeEach(async () => {
      renderHook(() =>
        useModules(dispatch, courseId, performanceControls.contextModulesPerPage, true)
      )
      await network.allRequestsReady()
      const [{response}] = getRequests()
      setPaginationLinkHeader(response, {last: 3})
      response.setJson(exampleData.contextModules.slice(0, 1))
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
    let result

    beforeEach(async () => {
      ;({result} = renderHook(() =>
        useModules(dispatch, courseId, performanceControls.contextModulesPerPage, true)
      ))
      await network.allRequestsReady()

      // Resolve the first page
      const [{response}] = getRequests()
      setPaginationLinkHeader(response, {last: 3})
      response.setJson(exampleData.contextModules.slice(0, 1))
      response.send()
      await network.allRequestsReady()

      // Resolve the remaining pages
      const [request2, request3] = getRequests().slice(1)
      setPaginationLinkHeader(request2.response, {last: 3})
      request2.response.setJson(exampleData.contextModules.slice(1, 2))
      request2.response.send()

      setPaginationLinkHeader(request3.response, {last: 3})
      request3.response.setJson(exampleData.contextModules.slice(2, 3))
      request3.response.send()
    })

    it('includes the loaded context modules when updating the gradebook', () => {
      expect(result.current.data).toStrictEqual(exampleData.contextModules)
    })
  })

  describe('if the first response does not link to the last page', () => {
    beforeEach(async () => {
      renderHook(() =>
        useModules(dispatch, courseId, performanceControls.contextModulesPerPage, true)
      )
      await network.allRequestsReady()
      const [{response}] = getRequests()
      response.setJson(exampleData.contextModules.slice(0, 1))
      response.send()
      await network.allRequestsReady()
    })

    it('does not send additional requests', () => {
      expect(getRequests().length).toStrictEqual(1)
    })
  })
})
