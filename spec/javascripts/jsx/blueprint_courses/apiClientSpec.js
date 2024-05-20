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
} from '@canvas/blueprint-courses/react/apiClient'
import axios from '@canvas/axios'

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

QUnit.module('Blueprint Course apiClient', {
  teardown() {
    if (sandbox) sandbox.restore()
    sandbox = null
  },
})

test('getCourse generated uri', () => {
  const axiosStub = mockAxiosClient('get', Promise.resolve({}))

  apiClient.getCourses(accountParams, getCourseParams)

  const url = new URL(axiosStub.args[0][0], mockBaseDomain)
  equal(url.pathname, `/api/v1/accounts/${accountParams.accountId}/courses`)
  equal(url.searchParams.get('per_page'), DEFAULT_PER_PAGE_PARAM)
  equal(url.searchParams.get('blueprint'), DEFAULT_BLUEPRINT_PARAM)
  equal(url.searchParams.get('blueprint_associated'), DEFAULT_BLUEPRINT_ASSOCIATED_PARAM)
  equal(url.searchParams.getAll('include[]')[0], DEFAULT_TERM_INCLUDE_PARAM)
  equal(url.searchParams.getAll('include[]')[1], DEFAULT_TEACHERS_INCLUDE_PARAM)
  equal(url.searchParams.get('teacher_limit'), DEFAULT_TEACHERS_LIMIT_PARAM)
  equal(url.searchParams.get('search_term'), getCourseParams.search)
  equal(url.searchParams.get('enrollment_term_id'), getCourseParams.term)
})

test('getCourse generated uri on subAccount given', () => {
  const expectedSubAccount = 'sub'
  const axiosStub = mockAxiosClient('get', Promise.resolve({}))

  apiClient.getCourses(accountParams, {...getCourseParams, subAccount: expectedSubAccount})

  const url = new URL(axiosStub.args[0][0], mockBaseDomain)
  equal(url.pathname, `/api/v1/accounts/${expectedSubAccount}/courses`)
})

test('getCourse generated uri on search contains URI reserved character', () => {
  const expectedSearch = 'search#reserved'
  const axiosStub = mockAxiosClient('get', Promise.resolve({}))

  apiClient.getCourses(accountParams, {...getCourseParams, search: expectedSearch})

  const url = new URL(axiosStub.args[0][0], mockBaseDomain)
  equal(url.searchParams.get('search_term'), expectedSearch)
})

test('getCourse generated uri on search starts with URI reserved character', () => {
  const expectedSearch = '#searchstring'
  const axiosStub = mockAxiosClient('get', Promise.resolve({}))

  apiClient.getCourses(accountParams, {...getCourseParams, search: expectedSearch})

  const url = new URL(axiosStub.args[0][0], mockBaseDomain)
  equal(url.searchParams.get('search_term'), expectedSearch)
})
