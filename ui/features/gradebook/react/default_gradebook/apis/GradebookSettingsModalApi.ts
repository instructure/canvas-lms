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

import axios from '@canvas/axios'
import {camelizeProperties, underscoreProperties} from '@canvas/convert-case'
import type {LatePolicyCamelized, LatePolicy} from '../gradebook.d'

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
    latePolicyResponseData.late_policy
  ) as LatePolicyCamelized
  return {latePolicy: camelizedData}
}

function underscoreLatePolicyData(latePolicyData: Partial<LatePolicyCamelized>) {
  return underscoreProperties(latePolicyData) as LatePolicy
}

export function fetchLatePolicy(courseId: string) {
  const url = `/api/v1/courses/${courseId}/late_policy`
  return axios
    .get<{
      late_policy: LatePolicy
    }>(url)
    .then(response => ({data: camelizeLatePolicyResponseData(response.data)}))
    .catch(error => {
      // if we get a 404 then we know the course does not
      // currently have a late policy set up
      if (error.response?.status === 404) {
        // eslint-disable-next-line promise/no-return-wrap
        return Promise.resolve({data: {latePolicy: DEFAULT_LATE_POLICY_DATA}})
      } else {
        // eslint-disable-next-line promise/no-return-wrap
        return Promise.reject(error)
      }
    })
}

export function createLatePolicy(courseId: string, latePolicyData: Partial<LatePolicyCamelized>) {
  const url = `/api/v1/courses/${courseId}/late_policy`
  const late_policy = underscoreLatePolicyData(latePolicyData)
  const data = {late_policy}
  return axios
    .post<{
      late_policy: LatePolicy
    }>(url, data)
    .then(response => ({data: camelizeLatePolicyResponseData(response.data)}))
}

export function updateLatePolicy(courseId: string, latePolicyData: Partial<LatePolicyCamelized>) {
  const url = `/api/v1/courses/${courseId}/late_policy`
  const data = {late_policy: underscoreLatePolicyData(latePolicyData)}
  return axios.patch(url, data)
}

export function updateCourseSettings(
  courseId: string,
  settings: {
    allowFinalGradeOverride: boolean
  }
) {
  const url = `/api/v1/courses/${courseId}/settings`
  return axios.put(url, underscoreProperties(settings)).then(response => ({
    data: camelizeProperties<{allowFinalGradeOverride: boolean}>(response.data),
  }))
}
