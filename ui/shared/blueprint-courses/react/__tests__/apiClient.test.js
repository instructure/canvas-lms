/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import apiClient, {
  DEFAULT_PER_PAGE_PARAM,
  DEFAULT_BLUEPRINT_PARAM,
  DEFAULT_BLUEPRINT_ASSOCIATED_PARAM,
  DEFAULT_TERM_INCLUDE_PARAM,
  DEFAULT_TEACHERS_INCLUDE_PARAM,
  DEFAULT_TEACHERS_LIMIT_PARAM,
} from '../apiClient'
import axios from '@canvas/axios'
import sinon from 'sinon'

let sandbox = null
const mockAxiosClient = (method, res) => {
  sandbox = sinon.createSandbox()
  return sandbox.stub(axios, method).returns(res)
}

const mockBaseDomain = 'http://canvas.docker'
const accountParams = {accountId: 1}
const getCourseParams = {
  search: 'foo',
  term: 'bar',
}

describe('Blueprint Course apiClient', () => {
  afterEach(() => {
    if (sandbox) sandbox.restore()
    sandbox = null
  })

  test('getCourse generated uri', async () => {
    const axiosStub = mockAxiosClient(
      'get',
      Promise.resolve({
        data: [],
        headers: {
          link: '<http://canvas.docker/api/v1/accounts/1/courses?page=2>; rel="next"',
        },
      })
    )

    await apiClient.getCourses(accountParams, getCourseParams)

    const url = new URL(axiosStub.args[0][0], mockBaseDomain)
    expect(url.pathname).toBe(`/api/v1/accounts/${accountParams.accountId}/courses`)
    expect(url.searchParams.get('per_page')).toBe(DEFAULT_PER_PAGE_PARAM)
    expect(url.searchParams.get('blueprint')).toBe(DEFAULT_BLUEPRINT_PARAM)
    expect(url.searchParams.get('blueprint_associated')).toBe(DEFAULT_BLUEPRINT_ASSOCIATED_PARAM)
    expect(url.searchParams.getAll('include[]')[0]).toBe(DEFAULT_TERM_INCLUDE_PARAM)
    expect(url.searchParams.getAll('include[]')[1]).toBe(DEFAULT_TEACHERS_INCLUDE_PARAM)
    expect(url.searchParams.get('teacher_limit')).toBe(DEFAULT_TEACHERS_LIMIT_PARAM)
    expect(url.searchParams.get('search_term')).toBe(getCourseParams.search)
    expect(url.searchParams.get('enrollment_term_id')).toBe(getCourseParams.term)
  })

  test('getCourse generated uri on subAccount given', async () => {
    const expectedSubAccount = 'sub'
    const axiosStub = mockAxiosClient(
      'get',
      Promise.resolve({
        data: [],
        headers: {
          link: '<http://canvas.docker/api/v1/accounts/sub/courses?page=2>; rel="next"',
        },
      })
    )

    await apiClient.getCourses(accountParams, {...getCourseParams, subAccount: expectedSubAccount})

    const url = new URL(axiosStub.args[0][0], mockBaseDomain)
    expect(url.pathname).toBe(`/api/v1/accounts/${expectedSubAccount}/courses`)
  })

  test('getCourse generated uri on search contains URI reserved character', async () => {
    const expectedSearch = 'search#reserved'
    const axiosStub = mockAxiosClient(
      'get',
      Promise.resolve({
        data: [],
        headers: {
          link: `<http://canvas.docker/api/v1/accounts/1/courses?search_term=${encodeURIComponent(
            expectedSearch
          )}&page=2>; rel="next"`,
        },
      })
    )

    await apiClient.getCourses(accountParams, {...getCourseParams, search: expectedSearch})

    const url = new URL(axiosStub.args[0][0], mockBaseDomain)
    expect(url.searchParams.get('search_term')).toBe(expectedSearch)
  })

  test('getCourse generated uri on search starts with URI reserved character', async () => {
    const expectedSearch = '#searchstring'
    const axiosStub = mockAxiosClient(
      'get',
      Promise.resolve({
        data: [],
        headers: {
          link: `<http://canvas.docker/api/v1/accounts/1/courses?search_term=${encodeURIComponent(
            expectedSearch
          )}&page=2>; rel="next"`,
        },
      })
    )

    await apiClient.getCourses(accountParams, {...getCourseParams, search: expectedSearch})

    const url = new URL(axiosStub.args[0][0], mockBaseDomain)
    expect(url.searchParams.get('search_term')).toBe(expectedSearch)
  })
})
