/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {camelizeProperties, underscoreProperties} from '@canvas/convert-case'
import type {LatePolicyCamelized, LatePolicy, CourseSettingsType} from '../gradebook.d'
import doFetchApi from '@canvas/do-fetch-api-effect'

export const DEFAULT_LATE_POLICY_DATA: LatePolicyCamelized = {
  lateSubmissionDeductionEnabled: false,
  lateSubmissionDeduction: 0,
  lateSubmissionInterval: 'day',
  lateSubmissionMinimumPercentEnabled: false,
  lateSubmissionMinimumPercent: 0,
  missingSubmissionDeductionEnabled: false,
  missingSubmissionDeduction: 100,
  newRecord: true,
} as const

function camelizeLatePolicyResponseData(latePolicyResponseData: {late_policy: LatePolicy}) {
  const camelizedData = camelizeProperties(
    latePolicyResponseData.late_policy,
  ) as LatePolicyCamelized
  return {latePolicy: camelizedData}
}

function underscoreLatePolicyData(latePolicyData: Partial<LatePolicyCamelized>) {
  return underscoreProperties(latePolicyData) as LatePolicy
}

export function fetchLatePolicy(courseId: string) {
  return doFetchApi<{late_policy: LatePolicy}>({
    path: `/api/v1/courses/${courseId}/late_policy`,
    method: 'GET',
  })
    .then(response => {
      if (response.json === undefined) {
        throw new Error('Response JSON is undefined')
      }

      return {data: camelizeLatePolicyResponseData(response.json)}
    })
    .catch(error => {
      // if we get a 404 then we know the course does not
      // currently have a late policy set up
      if (error.response?.status === 404) {
        return {data: {latePolicy: DEFAULT_LATE_POLICY_DATA}}
      }

      throw error
    })
}

export function createLatePolicy(courseId: string, latePolicyData: Partial<LatePolicyCamelized>) {
  return doFetchApi({
    path: `/api/v1/courses/${courseId}/late_policy`,
    method: 'POST',
    body: {late_policy: underscoreLatePolicyData(latePolicyData)},
  })
}

export function updateLatePolicy(courseId: string, latePolicyData: Partial<LatePolicyCamelized>) {
  return doFetchApi({
    path: `/api/v1/courses/${courseId}/late_policy`,
    method: 'PATCH',
    body: {late_policy: underscoreLatePolicyData(latePolicyData)},
  })
}

export function updateCourseSettings(
  courseId: string,
  settings: {
    allowFinalGradeOverride: boolean
  },
) {
  return doFetchApi<CourseSettingsType>({
    path: `/api/v1/courses/${courseId}/settings`,
    method: 'PUT',
    body: underscoreProperties(settings),
  }).then(response => {
    if (response.json === undefined) {
      throw new Error('Response JSON is undefined')
    }

    return {data: camelizeProperties<{allowFinalGradeOverride: boolean}>(response.json)}
  })
}
