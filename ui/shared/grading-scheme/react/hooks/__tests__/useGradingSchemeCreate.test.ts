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

import {renderHook} from '@testing-library/react-hooks/dom'
import type {GradingSchemeTemplate} from '../../../gradingSchemeApiModel'
import {ApiCallStatus} from '../ApiCallStatus'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const courseId = '11'
const accountId = '42'

const server = setupServer()

describe('useGradingSchemeCreateHook', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('renders for course context without error', () => {
    const {result} = renderHook(() => useGradingSchemeCreate())
    expect(result.error).toBeFalsy()
  })

  it('renders for account context without error', () => {
    const {result} = renderHook(() => useGradingSchemeCreate())
    expect(result.error).toBeFalsy()
  })

  it('makes a POST request for course context to create a grading scheme', async () => {
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
    let capturedPath = ''

    server.use(
      http.post(`/courses/${courseId}/grading_schemes`, ({request}) => {
        capturedPath = new URL(request.url).pathname
        return HttpResponse.json(gradingSchemeTemplate)
      }),
    )

    const {result} = renderHook(() => useGradingSchemeCreate())
    const createdGradingScheme = await result.current.createGradingScheme(
      'Course',
      courseId,
      gradingSchemeTemplate,
    )

    expect(capturedPath).toBe(`/courses/${courseId}/grading_schemes`)
    expect(createdGradingScheme).toEqual({
      title: 'My Course Grading Scheme',
      data,
      points_based: false,
      scaling_factor: 1.0,
    })
    expect(result.current.createGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })

  it('makes a POST request for account context to create a grading scheme', async () => {
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
    let capturedPath = ''

    server.use(
      http.post(`/accounts/${accountId}/grading_schemes`, ({request}) => {
        capturedPath = new URL(request.url).pathname
        return HttpResponse.json(gradingSchemeTemplate)
      }),
    )

    const {result} = renderHook(() => useGradingSchemeCreate())
    const createdGradingScheme = await result.current.createGradingScheme(
      'Account',
      accountId,
      gradingSchemeTemplate,
    )

    expect(capturedPath).toBe(`/accounts/${accountId}/grading_schemes`)
    expect(createdGradingScheme).toEqual({
      title: 'My Account Grading Scheme',
      data,
      points_based: false,
      scaling_factor: 1.0,
    })
    expect(result.current.createGradingSchemeStatus).toEqual(ApiCallStatus.COMPLETED)
  })
})
