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

import {termsQuery} from '../termsQuery'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {QueryFunctionContext} from '@tanstack/react-query'

jest.mock('@canvas/do-fetch-api-effect')

const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

describe('termsQuery', () => {
  const firstPageUrl = '/api/v1/accounts/1/terms'
  const secondPageUrl = '/api/v1/accounts/1/terms?page=2'
  const terms = [{id: '1', name: 'Test Term'}]
  const mockEnrollmentTerms = {enrollment_terms: terms}
  const mockPromiseResolveValue = {json: mockEnrollmentTerms, text: '', response: new Response()}
  const mockPromiseResolveValueWithLink = {
    json: mockEnrollmentTerms,
    text: '',
    response: new Response(),
    link: {next: {url: secondPageUrl}},
  }
  const signal = new AbortController().signal
  const queryKey: any = ['copy_course', 'enrollment_terms', '1']

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('should fetch enrollment terms data', async () => {
    mockDoFetchApi.mockResolvedValue(mockPromiseResolveValue)

    const result = await termsQuery({signal, queryKey} as QueryFunctionContext)

    expect(mockDoFetchApi).toHaveBeenCalledWith({
      path: firstPageUrl,
      fetchOpts: {signal},
    })
    expect(mockDoFetchApi).toHaveBeenCalledTimes(1)
    expect(result).toEqual(terms)
  })

  it('should iterate through pages', async () => {
    mockDoFetchApi
      .mockResolvedValueOnce(mockPromiseResolveValueWithLink)
      .mockResolvedValueOnce(mockPromiseResolveValue)

    await termsQuery({signal, queryKey} as QueryFunctionContext)
    expect(mockDoFetchApi).toHaveBeenCalledWith({
      path: firstPageUrl,
      fetchOpts: {signal},
    })
    expect(mockDoFetchApi).toHaveBeenCalledWith({
      path: secondPageUrl,
      fetchOpts: {signal},
    })
    expect(mockDoFetchApi).toHaveBeenCalledTimes(2)
  })
})
