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

import {useGradingSchemeUpdate} from '../useGradingSchemeUpdate'
import doFetchApi from '@canvas/do-fetch-api-effect'

import {renderHook} from '@testing-library/react-hooks/dom'
import type {GradingScheme, GradingSchemeUpdateRequest} from '../../../gradingSchemeApiModel'
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

describe('useGradingSchemeUpdateHook', () => {
  it('renders for course context without error', () => {
    const {result} = renderHook(() => useGradingSchemeUpdate())
    expect(result.error).toBeFalsy()
  })

  it('renders for account context without error', () => {
    const {result} = renderHook(() => useGradingSchemeUpdate())
    expect(result.error).toBeFalsy()
  })

  it('makes a PUT request for course context to update a grading scheme', async () => {
    const {result} = renderHook(() => useGradingSchemeUpdate())
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    const gradingSchemeUpdateRequest: GradingSchemeUpdateRequest = {
      id: 'some-id',
      data,
      title: 'My Course Grading Scheme',
      points_based: false,
      scaling_factor: 1.0,
    }

    const gradingScheme: GradingScheme = {
      ...gradingSchemeUpdateRequest,
      assessed_assignment: false,
      context_id: courseId,
      context_name: 'A Course Name',
      context_type: 'Course',
      permissions: {manage: true},
    }

    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: gradingScheme,
    })
    const updatedGradingScheme = await result.current.updateGradingScheme(
      'Course',
      courseId,
      gradingSchemeUpdateRequest
    )
    const lastCall = doFetchApi.mock.calls.pop()
    expect(lastCall[0]).toMatchObject({
      path: `/courses/${courseId}/grading_schemes/some-id`,
      method: 'PUT',
      body: gradingSchemeUpdateRequest,
    })

    expect(updatedGradingScheme).toEqual(gradingScheme)
    expect(result.current.updateGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })

  it('makes a PUT request for account context to update a grading scheme', async () => {
    const {result} = renderHook(() => useGradingSchemeUpdate())
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    const gradingSchemeUpdateRequest: GradingSchemeUpdateRequest = {
      id: 'some-id',
      data,
      title: 'My Account Grading Scheme',
      points_based: false,
      scaling_factor: 1.0,
    }
    const gradingScheme: GradingScheme = {
      ...gradingSchemeUpdateRequest,
      assessed_assignment: false,
      context_id: accountId,
      context_name: 'An Account Name',
      context_type: 'Account',
      permissions: {manage: true},
    }
    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: gradingScheme,
    })
    const updatedGradingScheme = await result.current.updateGradingScheme(
      'Account',
      accountId,
      gradingSchemeUpdateRequest
    )
    const lastCall = doFetchApi.mock.calls.pop()
    expect(lastCall[0]).toMatchObject({
      path: `/accounts/${accountId}/grading_schemes/some-id`,
      method: 'PUT',
      body: gradingSchemeUpdateRequest,
    })

    expect(updatedGradingScheme).toEqual(gradingScheme)
    expect(result.current.updateGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })
})
