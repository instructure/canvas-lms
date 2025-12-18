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

import {useAccountDefaultGradingSchemeUpdate} from '../useAccountDefaultGradingSchemeUpdate'
import {ApiCallStatus} from '../ApiCallStatus'

import {renderHook} from '@testing-library/react-hooks/dom'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const accountId = '42'

const server = setupServer()

describe('useAccountDefaultGradingSchemeUpdateHook', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('renders for course context without error', () => {
    const {result} = renderHook(() => useAccountDefaultGradingSchemeUpdate())
    expect(result.error).toBeFalsy()
  })

  it('renders for account context without error', () => {
    const {result} = renderHook(() => useAccountDefaultGradingSchemeUpdate())
    expect(result.error).toBeFalsy()
  })

  it('makes a POST request for account context to update a grading scheme', async () => {
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    let capturedPath = ''
    let capturedBody: unknown = null

    server.use(
      http.put(`/accounts/${accountId}/grading_schemes/account_default`, async ({request}) => {
        capturedPath = new URL(request.url).pathname
        capturedBody = await request.json()
        return HttpResponse.json({title: 'Scheme 1', data})
      }),
    )

    const {result} = renderHook(() => useAccountDefaultGradingSchemeUpdate())
    const loadedGradingScheme = await result.current.updateAccountDefaultGradingScheme(
      accountId,
      '99',
    )

    expect(capturedPath).toBe(`/accounts/${accountId}/grading_schemes/account_default`)
    expect(capturedBody).toEqual({id: '99'})
    expect(loadedGradingScheme).toEqual({title: 'Scheme 1', data})
    expect(result.current.updateAccountDefaultGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })
})
