/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useGradingSchemes} from '../useGradingSchemes'
import {ApiCallStatus} from '../ApiCallStatus'

import {renderHook} from '@testing-library/react-hooks/dom'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const courseId = '11'
const accountId = '42'

const server = setupServer()

describe('useGradingSchemesHook', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('renders for course context without error', () => {
    const {result} = renderHook(() => useGradingSchemes())
    expect(result.error).toBeFalsy()
  })

  it('renders for account context without error', () => {
    const {result} = renderHook(() => useGradingSchemes())
    expect(result.error).toBeFalsy()
  })

  it('makes a GET request for course context to load grading schemes', async () => {
    const data1 = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    const data2 = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    let capturedUrl = ''

    server.use(
      http.get(`/courses/${courseId}/grading_schemes`, ({request}) => {
        capturedUrl = request.url
        return HttpResponse.json([
          {title: 'Scheme 1', data: data1, id: 'id-1'},
          {title: 'Scheme 2', data: data2, id: 'id-2'},
        ])
      }),
    )

    const {result} = renderHook(() => useGradingSchemes())
    const loadedGradingSchemes = await result.current.loadGradingSchemes('Course', courseId)

    expect(capturedUrl).toContain(`/courses/${courseId}/grading_schemes`)
    expect(capturedUrl).toContain('include_archived=false')
    expect(loadedGradingSchemes).toEqual([
      {title: 'Scheme 1', data: data1, id: 'id-1'},
      {title: 'Scheme 2', data: data2, id: 'id-2'},
    ])
    expect(result.current.loadGradingSchemesStatus).toEqual(ApiCallStatus.COMPLETED)
  })

  it('makes a GET request for account context to load grading schemes', async () => {
    const data1 = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    const data2 = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    let capturedUrl = ''

    server.use(
      http.get(`/accounts/${accountId}/grading_schemes`, ({request}) => {
        capturedUrl = request.url
        return HttpResponse.json([
          {title: 'Scheme 1', data: data1},
          {title: 'Scheme 2', data: data2},
        ])
      }),
    )

    const {result} = renderHook(() => useGradingSchemes())
    const loadedGradingSchemes = await result.current.loadGradingSchemes('Account', accountId)

    expect(capturedUrl).toContain(`/accounts/${accountId}/grading_schemes`)
    expect(capturedUrl).toContain('include_archived=false')
    expect(loadedGradingSchemes).toEqual([
      {title: 'Scheme 1', data: data1},
      {title: 'Scheme 2', data: data2},
    ])
    expect(result.current.loadGradingSchemesStatus).toEqual(ApiCallStatus.COMPLETED)
  })
})
