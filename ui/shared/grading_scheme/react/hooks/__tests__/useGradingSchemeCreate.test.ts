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

import {useGradingSchemeCreate} from '../useGradingSchemeCreate'
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

describe('useGradingSchemeCreateHook', () => {
  it('renders for course context without error', () => {
    const {result} = renderHook(() => useGradingSchemeCreate())
    expect(result.error).toBeFalsy()
  })

  it('renders for account context without error', () => {
    const {result} = renderHook(() => useGradingSchemeCreate())
    expect(result.error).toBeFalsy()
  })

  it('makes a POST request for course context to create a grading scheme', async () => {
    const {result} = renderHook(() => useGradingSchemeCreate())
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    const gradingSchemeTemplate: GradingSchemeTemplate = {
      data,
      title: 'My Course Grading Scheme',
      points_based: false,
      scaling_factor: 1.0,
    }

    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: gradingSchemeTemplate,
    })
    const createdGradingScheme = await result.current.createGradingScheme(
      'Course',
      courseId,
      gradingSchemeTemplate
    )
    const lastCall = doFetchApi.mock.calls.pop()
    expect(lastCall[0]).toMatchObject({
      path: `/courses/${courseId}/grading_schemes`,
      method: 'POST',
      body: {},
    })

    expect(createdGradingScheme).toEqual({
      title: 'My Course Grading Scheme',
      data,
      points_based: false,
      scaling_factor: 1.0,
    })
    expect(result.current.createGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })

  it('makes a POST request for account context to create a grading scheme', async () => {
    const {result} = renderHook(() => useGradingSchemeCreate())
    const data = [
      {name: 'A', value: 0.9},
      {name: 'B', value: 0.8},
    ]
    const gradingSchemeTemplate: GradingSchemeTemplate = {
      data,
      title: 'My Account Grading Scheme',
      points_based: false,
      scaling_factor: 1.0,
    }

    doFetchApi.mockResolvedValue({
      response: {ok: true},
      json: gradingSchemeTemplate,
    })
    const createdGradingScheme = await result.current.createGradingScheme(
      'Account',
      accountId,
      gradingSchemeTemplate
    )
    const lastCall = doFetchApi.mock.calls.pop()
    expect(lastCall[0]).toMatchObject({
      path: `/accounts/${accountId}/grading_schemes`,
      method: 'POST',
      body: {},
    })

    expect(createdGradingScheme).toEqual({
      title: 'My Account Grading Scheme',
      data,
      points_based: false,
      scaling_factor: 1.0,
    })
    expect(result.current.createGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })
})
