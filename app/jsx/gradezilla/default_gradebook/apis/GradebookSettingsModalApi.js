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

import axios from 'axios';
import { camelize, underscore } from 'convert_case';

export const DEFAULT_LATE_POLICY_DATA = Object.freeze({
  lateSubmissionDeductionEnabled: false,
  lateSubmissionDeduction: 0,
  lateSubmissionInterval: 'day',
  lateSubmissionMinimumPercentEnabled: false,
  lateSubmissionMinimumPercent: 0,
  missingSubmissionDeductionEnabled: false,
  missingSubmissionDeduction: 0,
  newRecord: true
});

function camelizeLatePolicyResponseData (latePolicyResponseData) {
  const camelizedData = camelize(latePolicyResponseData.late_policy);
  return { latePolicy: camelizedData };
}

export function fetchLatePolicy (courseId) {
  const url = `/api/v1/courses/${courseId}/late_policy`;
  return axios.get(url)
    .then(response => (
      { data: camelizeLatePolicyResponseData(response.data) }
    ))
    .catch((error) => {
      // if we get a 404 then we know the course does not
      // currently have a late policy set up
      if (error.response && error.response.status === 404) {
        return Promise.resolve({ data: { latePolicy: DEFAULT_LATE_POLICY_DATA } });
      } else {
        return Promise.reject(error);
      }
    });
}

export function createLatePolicy (courseId, latePolicyData) {
  const url = `/api/v1/courses/${courseId}/late_policy`;
  const data = { late_policy: underscore(latePolicyData) };
  return axios.post(url, data).then(response => (
    { data: camelizeLatePolicyResponseData(response.data) }
  ));
}

export function updateLatePolicy (courseId, latePolicyData) {
  const url = `/api/v1/courses/${courseId}/late_policy`;
  const data = { late_policy: underscore(latePolicyData) };
  return axios.patch(url, data);
}

export default {
  DEFAULT_LATE_POLICY_DATA,
  fetchLatePolicy,
  createLatePolicy,
  updateLatePolicy
};
