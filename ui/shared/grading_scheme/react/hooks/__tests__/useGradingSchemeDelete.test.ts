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

import {useGradingSchemeDelete} from '../useGradingSchemeDelete'
import doFetchApi from '@canvas/do-fetch-api-effect'

import {renderHook} from '@testing-library/react-hooks/dom'
import type {GradingSchemeTemplate} from '../../../gradingSchemeApiModel'
import {ApiCallStatus} from '../ApiCallStatus'

const courseId = '11'
const accountId = '42'

jest.mock('@canvas/do-fetch-api-effect')
beforeEach(() => {
  doFetchApi.mockClear()
})

afterEach(() => {
  doFetchApi.mockClear()
})

describe('useGradingSchemeDeleteHook', () => {
  it('renders for course context without error', () => {
    const {result} = renderHook(() => useGradingSchemeDelete())
    expect(result.error).toBeFalsy()
  })

  it('renders for account context without error', () => {
    const {result} = renderHook(() => useGradingSchemeDelete())
    expect(result.error).toBeFalsy()
  })

  it('makes a DELETE request for course context to delete a grading scheme', async () => {
    const {result} = renderHook(() => useGradingSchemeDelete())

    const gradingSchemeTemplate: GradingSchemeTemplate = {
      data: [],
      title: 'My Course Grading Scheme',
      scaling_factor: 1.0,
      points_based: false,
    }

    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: gradingSchemeTemplate,
    })
    await result.current.deleteGradingScheme('Course', courseId, 'some-grading-scheme-id')
    const lastCall = doFetchApi.mock.calls.pop()
    expect(lastCall[0]).toMatchObject({
      path: `/courses/${courseId}/grading_schemes/some-grading-scheme-id`,
      method: 'DELETE',
    })
    expect(result.current.deleteGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })

  it('makes a DELETE request for account context to delete a grading scheme', async () => {
    const {result} = renderHook(() => useGradingSchemeDelete())

    const gradingSchemeTemplate: GradingSchemeTemplate = {
      data: [],
      title: 'My Account Grading Scheme',
      scaling_factor: 1.0,
      points_based: false,
    }

    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: gradingSchemeTemplate,
    })
    await result.current.deleteGradingScheme('Account', accountId, 'some-grading-scheme-id')
    const lastCall = doFetchApi.mock.calls.pop()
    expect(lastCall[0]).toMatchObject({
      path: `/accounts/${accountId}/grading_schemes/some-grading-scheme-id`,
      method: 'DELETE',
    })

    expect(result.current.deleteGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })
})
