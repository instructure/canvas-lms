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

import {useDefaultGradingScheme} from '../useDefaultGradingScheme'

import {renderHook} from '@testing-library/react-hooks/dom'
import {ApiCallStatus} from '../ApiCallStatus'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const courseId = '11'
const accountId = '42'

const server = setupServer()

describe('useDefaultGradingSchemeHook', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('renders for course context without error', () => {
    const {result} = renderHook(() => useDefaultGradingScheme())
    expect(result.error).toBeFalsy()
  })

  it('renders for account context without error', () => {
    const {result} = renderHook(() => useDefaultGradingScheme())
    expect(result.error).toBeFalsy()
  })

  it('makes a GET request for course context to load the default grading scheme', async () => {
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    let capturedPath = ''

    server.use(
      http.get(`/courses/${courseId}/grading_schemes/default`, ({request}) => {
        capturedPath = new URL(request.url).pathname
        return HttpResponse.json({title: 'Default Canvas Grading Scheme', data})
      }),
    )

    const {result} = renderHook(() => useDefaultGradingScheme())
    const defaultGradingScheme = await result.current.loadDefaultGradingScheme('Course', courseId)

    expect(capturedPath).toBe(`/courses/${courseId}/grading_schemes/default`)
    expect(defaultGradingScheme).toEqual({
      title: 'Default Canvas Grading Scheme',
      data,
    })
    expect(result.current.loadDefaultGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })

  it('makes a GET request for account context to load the default grading scheme', async () => {
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    let capturedPath = ''

    server.use(
      http.get(`/accounts/${accountId}/grading_schemes/default`, ({request}) => {
        capturedPath = new URL(request.url).pathname
        return HttpResponse.json({title: 'Default Canvas Grading Scheme', data})
      }),
    )

    const {result} = renderHook(() => useDefaultGradingScheme())
    const defaultGradingScheme = await result.current.loadDefaultGradingScheme('Account', accountId)

    expect(capturedPath).toBe(`/accounts/${accountId}/grading_schemes/default`)
    expect(defaultGradingScheme).toEqual({
      title: 'Default Canvas Grading Scheme',
      data,
    })
    expect(result.current.loadDefaultGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })

  it('throws error and sets an error status if the GET request to load the default grading scheme fails', async () => {
    server.use(
      http.get(
        '/courses/:contextId/grading_schemes/default',
        () => new HttpResponse(null, {status: 500, statusText: 'I should fail'}),
      ),
      http.get(
        '/accounts/:contextId/grading_schemes/default',
        () => new HttpResponse(null, {status: 500, statusText: 'I should fail'}),
      ),
    )

    const {result} = renderHook(() => useDefaultGradingScheme())
    await expect(result.current.loadDefaultGradingScheme('Course', courseId)).rejects.toThrow()
    expect(result.current.loadDefaultGradingSchemeStatus).toEqual(ApiCallStatus.FAILED)
  })
})
