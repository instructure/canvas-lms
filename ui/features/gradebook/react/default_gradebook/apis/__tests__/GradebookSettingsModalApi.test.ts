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

import _ from 'lodash'
import {underscoreProperties} from '@canvas/convert-case'
import fetchMock from 'fetch-mock'
import {
  DEFAULT_LATE_POLICY_DATA,
  fetchLatePolicy,
  createLatePolicy,
  updateCourseSettings,
  updateLatePolicy,
} from '../GradebookSettingsModalApi'
import type {LatePolicyCamelized} from '../../gradebook.d'

const latePolicyData: LatePolicyCamelized & {id: string} = {
  id: '15',
  missingSubmissionDeductionEnabled: false,
  missingSubmissionDeduction: 76.0,
  lateSubmissionDeductionEnabled: true,
  lateSubmissionDeduction: 10.0,
  lateSubmissionInterval: 'day',
  lateSubmissionMinimumPercentEnabled: true,
  lateSubmissionMinimumPercent: 40.0,
}

const lastCallRequestBody = (fetchMockStub: fetchMock.FetchMockStatic) => {
  const lastOptions = fetchMockStub.lastOptions()
  if (!lastOptions) return undefined

  // fetch-mock library needs to be updated; this is a workaround.
  const body = lastOptions.body as unknown as string
  return JSON.parse(body)
}

describe('GradebookSettingsModalApi', () => {
  describe('fetchLatePolicy success', () => {
    beforeEach(() => {
      fetchMock.get('/api/v1/courses/19/late_policy', {
        late_policy: underscoreProperties(latePolicyData),
      })
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('returns the late policy', async () => {
      const {data} = await fetchLatePolicy('19')
      expect(data).toEqual({latePolicy: latePolicyData})
    })
  })

  describe('fetchLatePolicy when late policy does not exist', () => {
    beforeEach(() => {
      fetchMock.get('/api/v1/courses/19/late_policy', 404)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('returns the default late policy', async () => {
      const {data} = await fetchLatePolicy('19')
      expect(data).toEqual({latePolicy: DEFAULT_LATE_POLICY_DATA})
    })
  })

  describe('fetchLatePolicy when the request fails', () => {
    beforeEach(() => {
      fetchMock.get('/api/v1/courses/19/late_policy', 500)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('throws an error when the response is not a 200 or a 404', async () => {
      await expect(fetchLatePolicy('19')).rejects.toThrow()
    })
  })

  describe('createLatePolicy', () => {
    let createStub: fetchMock.FetchMockStatic
    let latePolicyCreationData: Partial<typeof latePolicyData>
    let url: string

    beforeEach(() => {
      latePolicyCreationData = {...latePolicyData, id: undefined}
      url = '/api/v1/courses/19/late_policy'
      const responseBody = {late_policy: underscoreProperties(latePolicyData)}
      createStub = fetchMock.post(url, responseBody)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('includes data to create a late_policy', async () => {
      await createLatePolicy('19', latePolicyCreationData)
      const body = lastCallRequestBody(createStub)
      expect(body).toEqual({late_policy: underscoreProperties(latePolicyCreationData)})
    })

    it('returns the late policy', async () => {
      const {json} = await createLatePolicy('19', latePolicyCreationData)
      expect(json).toEqual({late_policy: underscoreProperties(latePolicyData)})
    })
  })

  describe('updateLatePolicy', () => {
    let url: string
    let changes: Pick<LatePolicyCamelized, 'lateSubmissionInterval'>
    let updatePolicyStub: fetchMock.FetchMockStatic

    beforeEach(() => {
      url = '/api/v1/courses/19/late_policy'
      changes = {lateSubmissionInterval: 'hour'}
      updatePolicyStub = fetchMock.patch(url, 204)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('includes data to update a late_policy', async () => {
      await updateLatePolicy('19', changes)
      const body = lastCallRequestBody(updatePolicyStub)
      expect(body).toEqual({late_policy: underscoreProperties(changes)})
    })

    it('returns a 204 (successfully fulfilled request and no content)', async () => {
      const {response} = await updateLatePolicy('19', changes)
      expect(response.status).toEqual(204)
    })
  })

  describe('updateCourseSettings', () => {
    let updateStub: fetchMock.FetchMockStatic
    let responseData: {allow_final_grade_override: boolean}

    beforeEach(() => {
      responseData = {allow_final_grade_override: true}
      updateStub = fetchMock.put('/api/v1/courses/1201/settings', responseData)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('sends a request to update course settings', async () => {
      await updateCourseSettings('1201', {allowFinalGradeOverride: true})
      expect(updateStub.called()).toBe(true)
    })

    it('normalizes the request body with snake case', async () => {
      await updateCourseSettings('1201', {allowFinalGradeOverride: true})
      const body = lastCallRequestBody(updateStub)
      expect(body).toEqual({allow_final_grade_override: true})
    })

    it('normalizes the response body with camel case upon success', async () => {
      const {data} = await updateCourseSettings('1201', {allowFinalGradeOverride: true})
      expect(data).toEqual({allowFinalGradeOverride: true})
    })

    it('does not catch errors', async () => {
      // Catching errors is the responsibility of the consumer.
      updateStub.put('/api/v1/courses/1201/settings', 500, {overwriteRoutes: true})
      try {
        await updateCourseSettings('1201', {allowFinalGradeOverride: true})
      } catch (error) {
        if (error instanceof Error) {
          expect(error.message).toContain('500')
        }
      }
    })
  })
})
