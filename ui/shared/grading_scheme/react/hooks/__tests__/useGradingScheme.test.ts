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

import {useGradingScheme} from '../useGradingScheme'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {ApiCallStatus} from '../ApiCallStatus'

import {renderHook} from '@testing-library/react-hooks/dom'

const courseId = '11'
const accountId = '42'

jest.mock('@canvas/do-fetch-api-effect')
beforeEach(() => {
  doFetchApi.mockClear()
})

afterEach(() => {
  doFetchApi.mockClear()
})

describe('useGradingSchemeHook', () => {
  it('renders for course context without error', () => {
    const {result} = renderHook(() => useGradingScheme())
    expect(result.error).toBeFalsy()
  })

  it('renders for account context without error', () => {
    const {result} = renderHook(() => useGradingScheme())
    expect(result.error).toBeFalsy()
  })

  it('makes a GET request for course context to load grading scheme', async () => {
    const {result} = renderHook(() => useGradingScheme())
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]

    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: {title: 'Scheme 1', data},
    })
    const loadedGradingScheme = await result.current.loadGradingScheme(
      'Course',
      courseId,
      'some-id'
    )
    const lastCall = doFetchApi.mock.calls.pop()
    expect(lastCall[0]).toMatchObject({
      path: `/courses/${courseId}/grading_schemes/some-id`,
      method: 'GET',
    })

    expect(loadedGradingScheme).toEqual({title: 'Scheme 1', data})
    expect(result.current.loadGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })

  it('makes a GET request for account context to load grading scheme', async () => {
    const {result} = renderHook(() => useGradingScheme())
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]

    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: {title: 'Scheme 1', data},
    })
    const loadedGradingScheme = await result.current.loadGradingScheme(
      'Account',
      accountId,
      'some-id'
    )
    const lastCall = doFetchApi.mock.calls.pop()
    expect(lastCall[0]).toMatchObject({
      path: `/accounts/${accountId}/grading_schemes/some-id`,
      method: 'GET',
    })

    expect(loadedGradingScheme).toEqual({title: 'Scheme 1', data})

    expect(result.current.loadGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })
})
