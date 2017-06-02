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

function toParams (id, timeFrame) {
  return {
    params: {
      id,
      start_time: timeFrame.from,
      end_time: timeFrame.to,
      per_page: 20
    }
  };
}

function getByAssignment (assignmentId, timeFrame = {from: '', to: ''}) {
  const url = encodeURI(`/api/v1/audit/grade_change/assignments/${assignmentId}`);
  const params = toParams(assignmentId, timeFrame);

  return axios.get(url, params);
}

function getByGrader (graderId, timeFrame = {from: '', to: ''}) {
  const url = encodeURI(`/api/v1/audit/grade_change/graders/${graderId}`);
  const params = toParams(graderId, timeFrame);

  return axios.get(url, params);
}

function getByStudent (studentId, timeFrame = {from: '', to: ''}) {
  const url = encodeURI(`/api/v1/audit/grade_change/students/${studentId}`);
  const params = toParams(studentId, timeFrame);

  return axios.get(url, params);
}

export default { getByAssignment, getByGrader, getByStudent };
